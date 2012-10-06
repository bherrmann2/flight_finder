import mmap, os.path
import structs, gexceptions, index.hash
import sys

if sys.maxint == 2147483647:
    # we need to map 2 files, so max map size is max address space
    # divided by 2
    _MAX_MAP_SIZE = 2147483648
else:
    _MAX_MAP_SIZE = float('inf')

class GraphObjectFile(object):
    def __init__(self, filename, filetype, object_size, indexed=True):
        """Initialize a GraphObjectFile.  Both edge and node objects
        are stored with the same API.  If the files do not already exist,
        a "dbfiles" directory is created in the current working directory
        and the new files are initialized there.

        Parameters
        ----------
        filename: name of the file to create
        filetype: string name for the type of object that will be placed
                  in the file, i.e. "nodes" or "edges"
        object_size: the size of the binary string that represents the object
        indexed: whether or not to generate an index for this file.
                 If an index is used, all objects will be indexed by label.
                 While labels do not have to be unique, as of this version
                 only the last object entered with that label will be in the index
        """
        if not os.path.isdir('dbfiles'):
            os.mkdir('dbfiles')
        self.filename = 'dbfiles/%s.vgraph.%s' % (filename, filetype)
        self.garbage = GarbageFile(filename, filetype)
        self.__next_id = 0
        self.__object_size = object_size
        self.__used_recycled_id = False
        if not os.path.isfile(self.filename):
            self.fh = open(self.filename, 'wb')
            self.fh.seek(1024)
            self.fh.write('0')
            self.fh.seek(0)
            self.fh.close()
            self.fh = open(self.filename, 'r+b')
            self.map_db_file()
        else:
            self.fh = open(self.filename, 'r+b')
            self.map_db_file()
        if indexed:
            self.associate_index(filename, filetype)
    
    def __setup_new_file(self):
        """Private method that writes the object files bookkeeper structure
        at the beginning of the file.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.db_map.seek(0)
        bin_str = structs.pack_bookkeeper(0)
        self.db_map.write(bin_str)
    
    def get_next_id(self):
        """Returns the next available ID for an object in this file

        Parameters
        ----------
        None

        Returns
        -------
        Integer
        """
        if self.garbage and self.__used_recycled_id == False:
            self.__used_recycled_id = True
            self.__next_id = self.garbage._ids[0]
            return self.__next_id
        self.__used_recycled_id = False
        return self.__next_id
    
    def map_db_file(self):
        """Maps the file associated with this GraphObjectFile into memory.
        On a 32-bit system, up to 2 GB will be mapped (the implementation expects
        to be mapping 2 files - nodes and edges).  On a 64-bit system, the
        maximum map size is functionally unlimited.  Once the file is mapped,
        the GraphObjectFile will have its bookkeeping attributes available.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        self.size = os.path.getsize(self.filename)
        if self.size < _MAX_MAP_SIZE:
            self.db_map = mmap.mmap(self.fh.fileno(), self.size)
        else:
            self.db_map = mmap.mmap(self.fh.fileno(), _MAX_MAP_SIZE, offset=0)
        self.db_map.seek(0)
        bin_str = self.db_map.read(structs._SIZEOF_BOOKKEEPER)
        self.__next_id = structs.unpack_bookkeeper(bin_str)[0]
    
    def __update_next_id(self):
        """Update the bookkeeping structure at the head of the file
        with the new next available object ID

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self.db_map.seek(0)
        bin_str = structs.pack_bookkeeper(self.__next_id)
        self.db_map.write(bin_str)
    
    def associate_index(self, filename, filetype):
        """Associate an index with this particular GraphObjectFile.  If
        an index is associated with the file, then all writes will be
        automatically indexed by their label

        Parameters
        ----------
        filename: name of the file to create
        filetype: string name for the type of object that will be placed
                  in the file, i.e. "nodes" or "edges"

        Returns
        -------
        None"""
        self._index = index.hash.HashIndex(filename, filetype)
    
    def write(self, offset, label, bin_str, indexed=True, new=True):
        """Write a binary string to the file at a given offset.  A label
        must be explicitly passed to this method for indexing purposes.  If
        the new kwarg is True, then the next available object ID for this file
        will be incremented if there are no deleted IDs to use.  If there are,
	    then one of those will be used instead.
	
	    Otherwise, it will be assumed this is an overwrite to an existing object.

        Parameters
        ----------
        offset: an integer offset into the memory mapping to write to
        label: the label of the graph object being added
        bin_str: the binary string to be written (must match the size
                 passed to the GraphObjectFile on initialization
        indexed: boolean for whether to index this object
        new: boolean for whether this is a new object or an update

        Returns
        -------
        None"""
        self.db_map.seek((offset*self.__object_size)+structs._SIZEOF_BOOKKEEPER)
        try:
            self.db_map.write(bin_str)
        except:
            self.size *= 2
            if self.size < _MAX_MAP_SIZE:
                self.db_map.resize(self.size)
                self.db_map.write(bin_str)
        if new:
            if indexed:
                if hasattr(self, '_index'):
                    self._index[label] = self.__next_id 
            if not self.__used_recycled_id:
                self.__next_id += 1
                self.__update_next_id()
            else:
                self.__used_recycled_id = False
                self.garbage.pop()
    
    def read(self, offset):
        """Read a binary string from the specified offset in the memory
        mapping.  A length of the returned string will be equal to the
        object_size parameter passed on object initialization.

        Parameters
        ----------
        offset: an integer offset into the memory mapping to read from

        Returns
        -------
        String"""
        self.db_map.seek((offset*self.__object_size)+structs._SIZEOF_BOOKKEEPER)
        bin = self.db_map.read(self.__object_size)
        if not len(bin.strip('\x01')):
            return False
        if not len(bin.strip('\x00')):
            raise gexceptions.NotInDBError('Object not in database')
        return bin

    def remove(self, offset):
        """Remove an object from the GraphObjectFile.  The offset indicates
	    where in the file to perform the deletion.  The size of the data that
	    will be deleted is the private object_size attribute initialized at
	    the initialization of the file.

        Parameters
        ----------
        offset: an integer offset into the memory mapping to read from

        Returns
        -------
	    None"""
        self.db_map.seek((offset*self.__object_size)+structs._SIZEOF_BOOKKEEPER)
        bin_str = '\x01' * self.__object_size
        self.db_map.write(bin_str)
        self.garbage.append(offset)
    
    def allocate(self):
        """This allocates space for an object without actually writing it in.
        Example: allocating the space for the first edge tied to a node for when
        someone eventually creates an edge.

        Parameters
        ----------
        None

        Returns
        ----------
        None
        """
        try:
            self.db_map.seek((self.__next_id*self.__object_size)+structs._SIZEOF_BOOKKEEPER)
        except:
            self.size *= 2
            if self.size < _MAX_MAP_SIZE:
                self.db_map.resize(self.size)
        #if there are garbage IDs to be recycled, why bother allocating anything?
        if not self.__used_recycled_id:
            self.__next_id += 1
            self.__update_next_id()
        else:
            self.__used_recycled_id = False
            self.garbage.pop()
    
    def close(self):
        """Flush the contents of the file buffers for this GraphObjectFile
        and any underlying index.  After closing the file, any further reads
        or writes will raise an IOError.

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self.db_map.flush()
        self.db_map.close()
        if hasattr(self, '_index'):
            self._index.close()
        self.fh.close()

class GarbageFile(object):
    def __init__(self, filename, filetype):
        self.filename = 'dbfiles/%s.vgraph.%s.garbage' % (filename, filetype)
        self.__object_size = structs._SIZEOF_GARBAGE 
        self._ids = []
        if not os.path.isfile(self.filename):
            self.fh = open(self.filename, 'wb')
            self.fh.seek(1024)
            self.fh.write('0')
            self.fh.seek(0)
            self.fh.close()
            self.fh = open(self.filename, 'r+b')
            self.map_db_file()
            self.__count = 0
        else:
            self.fh = open(self.filename, 'r+b')
            self.map_db_file()
            self._read_in_ids()

    def __len__(self):
        return len(self._ids)

    def __update_count(self):
        """Update the bookkeeping structure at the head of the file
        with the total count of reusable IDs

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self.db_map.seek(0)
        bin_str = structs.pack_garbage(self.__count)
        self.db_map.write(bin_str)

    def map_db_file(self):
        """Maps the file associated with this GarbageFile into memory.
        On a 32-bit system, up to 2 GB will be mapped (the implementation expects
        to be mapping 2 files - nodes and edges).  On a 64-bit system, the
        maximum map size is functionally unlimited.  Once the file is mapped,
        the GarbageFile will have its count attribute available.

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self.size = os.path.getsize(self.filename)
        if self.size < _MAX_MAP_SIZE:
            self.db_map = mmap.mmap(self.fh.fileno(), self.size)
        else:
            self.db_map = mmap.mmap(self.fh.fileno(), _MAX_MAP_SIZE, offset=0)
        self.db_map.seek(0)
        bin_str = self.db_map.read(structs._SIZEOF_GARBAGE)
        self.__count = structs.unpack_bookkeeper(bin_str)[0]

    def _read_in_ids(self):
        self.db_map.seek(structs._SIZEOF_GARBAGE)
        #this is reversed because its easier to pop stuff off the end
	    #of the file later than pop from the beginning and have to move
	    #everything up when an ID is reclaimed
        for i in range(self.__count, 0, -1):
            bin = self.db_map.read(self.__object_size)
            _id = structs.unpack_garbage(bin)
            self._ids.append(_id[0])
	
    def append(self, _id):
        """Append an object ID to be "garbage collected" to this GarbageFile.
        Once appended, the ID will be available for reuse by the ObjectFile
        that this GarbageFile is associated with.

        Parameters
        ----------
        _id: the integer ID to append to this GarbageFile

        Returns
        -------
        None"""
        self._ids.insert(0, _id)
        self.db_map.seek((structs._SIZEOF_GARBAGE * self.__count) + structs._SIZEOF_GARBAGE)
        bin_str = structs.pack_garbage(_id)
        self.db_map.write(bin_str)
        self.__count += 1
        self.__update_count()

    def pop(self):
        """Pop an object ID off the garbage stack for use by an ObjectFile.
        Popping an ID will remove that ID from the garbage bin.

        Parameters
        ----------
        None

        Returns
        -------
        Integer"""
        self.db_map.seek((structs._SIZEOF_GARBAGE * self.__count) + structs._SIZEOF_GARBAGE)
        bin_str = '\x00' * structs._SIZEOF_GARBAGE
        self.db_map.write(bin_str)
        self.__count -= 1
        self.__update_count()
        return self._ids.pop(0)

