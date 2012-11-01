#! /usr/bin/env python
import os, struct, math, re

_item_fmt = '50sL'
_SIZEOF_ITEM = struct.calcsize(_item_fmt)

_bookkeeper_fmt = 'LL'
_SIZEOF_BOOKKEEPER = struct.calcsize(_bookkeeper_fmt)

def _binary(n):
    n += 2**32
    return bin(n)[-32:]

class HashIndex(object):
    def __init__(self, filename, filetype):
        """Initialize a HashIndex.  Both edge and node objects
        If the file does not already exist, a "dbfiles" directory
        is created in the current working directory and the new
        file is initialized there.

        Parameters
        ----------
        filename: name of the file to create
        filetype: string name for the type of object that will be placed
                  in the file, i.e. "nodes" or "edges" """
        self.filename = 'dbfiles/%s.vgraph.%s.index' % (filename, filetype)
        if not os.path.isfile(self.filename):
            self.fh = open(self.filename, 'wb')
            self.fh.seek(0)
            self.fh.write(struct.pack(_bookkeeper_fmt, 0, 8))
            self.fh.seek(_SIZEOF_BOOKKEEPER)
            self.fh.write('0'*8*_SIZEOF_ITEM)
            self.buckets = 8
            self.__num_items = 0
            self.__bits_to_use = int(math.log(self.buckets, 2))
            self.fh.close()
            self.fh = open(self.filename, 'r+b')
        else:
            self.fh = open(self.filename, 'r+b')
            self.__num_items, self.buckets = struct.unpack(_bookkeeper_fmt,
                    self.fh.read(_SIZEOF_BOOKKEEPER))
            self.__bits_to_use = int(math.log(self.buckets, 2))

    def keys(self):
        """Get the full listing of keys stored in this index.  Analogous
        to the standard Python dictionary keys method.

        Parameters
        ----------
        None

        Returns
        -------
        List of strings"""
        results = []
        for i in xrange(_SIZEOF_BOOKKEEPER, os.path.getsize(self.filename),
                        _SIZEOF_ITEM):
            self.fh.seek(i)
            current_item = self.fh.read(_SIZEOF_ITEM)
            if len(current_item) < 24:
                break
            item = struct.unpack(_item_fmt, current_item)
            if item[0][0] == '0':
                continue
            results.append(re.sub(r'\x00', '', item[0]))
            self.fh.seek(i)
        return results

    def _grow(self):
        """Doubles the size of the underlying hash table and re-indexes
        the original values using the newly created space.  This method
        is called internally when the number of free buckets falls to 1/3
        of the total count

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        #this will temporarily store the current indexes keys and values
        #as the hash index file is grown
        tmp = {}
        self.buckets *= 2
        self.__bits_to_use += 1
        self.fh.flush()
        for i in xrange(_SIZEOF_BOOKKEEPER, os.path.getsize(self.filename),
                        _SIZEOF_ITEM):
            self.fh.seek(i)
            current_item = self.fh.read(_SIZEOF_ITEM)
            if len(current_item) < 24:
                break
            item = struct.unpack(_item_fmt, current_item)
            if item[0][0] == '0':
                continue
            tmp[re.sub(r'\x00', '', item[0])] = item[1]
            self.fh.seek(i)
        self.fh.seek(_SIZEOF_BOOKKEEPER)
        self.fh.write('0'*self.buckets*_SIZEOF_ITEM)
        #the num_items attribute will be recounted by the _write
        #method
        self.__num_items = 0
        for t in tmp:
            self.__setitem__(t, tmp[t])

    @classmethod    
    def _hash(self, label, num_bits):
        """Returns a hash value for the passed label.  Depending
        on how many num_bits are specified, will return a value
        that many bits long

        Parameters
        ----------
        label: the object label to be hashed
        num_bits: the number of bits in the return value

        Returns
        -------
        Integer"""
        return int(_binary(hash(label))[-num_bits:], 2)

    def _write(self, index, key, bin_str):
        """Write the specified binary value into the hash table with
        its associated key.  This particular implementation uses a
        linear probing strategy to resolve collisions.

        Parameters
        ----------
        index: the index into the hash table where the data will be written
        key: the original key passed in to be hashed
        bin_str: the binary value associated with the key

        Returns
        -------
        None"""
        self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
        current_item = self.fh.read(_SIZEOF_ITEM)
        item = struct.unpack(_item_fmt, current_item)
        added_item = False
        if item[0][0] == '0':
            self.__num_items += 1
            added_item = True
            self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
            self.fh.write(bin_str)
        elif re.sub(r'\x00', '', item[0]) != key:
            #probe linearly to find an empty slot
            while item[0][0] != '0':
                index += 1
                self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
                current_item = self.fh.read(_SIZEOF_ITEM)
                if len(current_item) < 24:
                    index = 0
                    continue
                #we reached the end and need to start over
                item = struct.unpack(_item_fmt, current_item)
            self.__num_items += 1
            added_item = True
            self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
            self.fh.write(bin_str)
        else:
            #if overwriting an existing item, don't increment the number
            #of items count
            self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
            self.fh.write(bin_str)
        if self.__num_items / float(self.buckets) > .66:
            self._grow()
        #checking the if-clause again is probably cheaper than an
        #unnecessary file seek
        if added_item:
            self.fh.seek(0)
            self.fh.write(struct.pack(_bookkeeper_fmt, self.__num_items, self.buckets))

    def _read(self, index, key):
        """Read the value in the hash table associated with the specified
        key.  This implementation uses a linear probing strategy if the first
        slot does not contain the right key.

        Parameters
        ----------
        index: the index to begin looking in the hash table
        key: the original key to be searched

        Returns
        -------
        A string of binary data"""
        self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
        bin_str = self.fh.read(_SIZEOF_ITEM)
        item = struct.unpack(_item_fmt, bin_str)
        if item[0][0] == '0':
            raise KeyError('Value not indexed')
        elif re.sub(r'\x00', '', item[0]) != key:
            #probe linearly to find the right key to return
            original_index = index
            while re.sub(r'\x00', '', item[0]) != key:
                index += 1
                self.fh.seek((index * _SIZEOF_ITEM) + _SIZEOF_BOOKKEEPER)
                current_item = self.fh.read(_SIZEOF_ITEM)
                #we hit the end and need to start over
                if len(current_item) < 24:
                    index = 0
                    continue
                item = struct.unpack(_item_fmt, current_item)
                if original_index == index:
                    raise KeyError('Value not indexed')
        return item[1]

    def __setitem__(self, key, item):
        index = self._hash(key, self.__bits_to_use)
        self._write(index, key, struct.pack(_item_fmt, key, item))

    def index(self, key, item):
        """Inserts an item into the hash index.  Is equivalent
        to using the __setitem__ syntax (i.e. index[key] = value).
        As of this version, the hash index only stores integers.

        Parameters
        ----------
        key: the key to hash the item by
        item: the data to be stored

        """
        index = self._hash(key, self.__bits_to_use)
        self._write(index, key, struct.pack(_item_fmt, key, item))

    def __getitem__(self, key):
        index = self._hash(key, self.__bits_to_use)
        return self._read(index, key)

    def get(self, key, default=None):
        """Returns an item based on the key.  Analogous to the
        __getitem__ syntax (i.e. value = index[key]), but does not
        throw an exception if the item is not found.  As with the
        Python dictionary's get() method, instead the argument
        supplied to default will be returned.

        Parameters
        ----------
        key: the key to search for
        default: the value to return if the key is not found

        Returns
        -------
        Integer"""
        index = self._hash(key, self.__bits_to_use)
        try:
            value = self._read(index, key)
            return value
        except KeyError:
            return default

    def close(self):
        """Flushes the file buffer and closes the file.  Any subsequent
        reads or writes will result in an IOException.

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self.fh.flush()
        self.fh.close()
        
