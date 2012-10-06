import struct

## Pack format strings for bookkeeping structures ##
_bookkeeper_fmt = '=L'
_SIZEOF_BOOKKEEPER = struct.calcsize(_bookkeeper_fmt)

## Pack format strings for graph objects ##
_node_fmt = '=L50sLL'
_SIZEOF_NODE = struct.calcsize(_node_fmt)
_edge_fmt = '=LLL50sILL'
_SIZEOF_EDGE = struct.calcsize(_edge_fmt)
_LABEL_LEN = 50

_garbage_fmt='=L'
_SIZEOF_GARBAGE = struct.calcsize(_garbage_fmt)

def pack_garbage(next_id):
    return struct.pack(_garbage_fmt, next_id)

def unpack_garbage(garbage_struct):
    return struct.unpack(_garbage_fmt, garbage_struct)

def pack_bookkeeper(next_id):
    return struct.pack(_bookkeeper_fmt, next_id)

def unpack_bookkeeper(bookkeeper_struct):
    return struct.unpack(_bookkeeper_fmt, bookkeeper_struct)

def pack_node(node_id, first_edge, last_edge, label=''):
    return struct.pack(_node_fmt, node_id, label, first_edge, last_edge)

def pack_edge(cost, node_1, node_2, previous_edge, next_edge, label='', direction=0):
    """Pack an edge into a binary struct for writing to disk.
    
    Parameters
    ----------
    node_1: the "from node"
    node_2: the "to node"
    previous_edge: the offset in the db file where the previous edge can be found
    next_edge: the offset in the db file where the next edge can be found
    label: the label for the edge
    direction: 0 for undirected, 1 for incoming, 2 for outgoing
    """
    return struct.pack(_edge_fmt, cost, node_1,
                       node_2, label, direction, previous_edge, next_edge)
        
def unpack_node(node_struct):
    return struct.unpack(_node_fmt, node_struct)

def unpack_edge(edge_struct):
    return struct.unpack(_edge_fmt, edge_struct)
