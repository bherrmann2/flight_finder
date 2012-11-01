from vgraph.data import storage, primitives, structs, gexceptions

class Graph(object):
    def __init__(self, name):
        """Initializes a new Graph with a given name.  Database files will be
        automatically generated for edges and nodes if a graph by this name does
        not exist.  By default, only nodes are indexed by label.  

        Parameters
        ----------
        name: a string name for the graph"""
        self.name = name
        self._node_map = storage.GraphObjectFile(name, 'nodes', structs._SIZEOF_NODE)
        self._edge_map = storage.GraphObjectFile(name, 'edges', structs._SIZEOF_EDGE,
                                                    indexed=False)
    
    def create_node(self, label, indexed=True):
        """Create node for this graph.  Label cannot be None and must be
        a string.  All created nodes will be indexed by label for later
        searching.

        Parameters
        ----------
        label: string label for this node
        indexed: boolean for whether to index the node label

        Returns
        -------
        A vgraph Node object"""
        n = primitives.Node(self, label=label)
        n.id = self._node_map.get_next_id()
        n._set_first_edge_offset(self._edge_map.get_next_id())
        n._set_last_edge_offset(self._edge_map.get_next_id())
        self._node_map.write(n.id, n.label, n._to_struct(),
                             indexed=indexed, new=True)
        self._edge_map.allocate()
        return n
    
    def node(self, node_id=None, label=None):
        """Search for a node based either on node ID or on its label.
        If node ID is specified, then this method will search the node
        database directly.  If there is no node ID but a label is specified,
        this method will use an index to locate the node.  One of these
        parameters must not be None.  If the node cannot be found, a
        NotInDBError is thrown.

        Parameters
        ----------
        node_id: an integer ID to search for
        label: a string label to search for

        Returns
        -------
        A vgraph Node object"""
        if node_id is None and label is None:
            raise ValueError('Must supply either a label or a node id to search')
        if node_id is not None:
            bin_str = self._node_map.read(node_id)
            if not bin_str:
                return None
                #raise gexceptions.DeletedError
        else:
            offset = self._node_map._index.get(label)
            if offset is not None:
                bin_str = self._node_map.read(offset)
            else:
                return None
        n = primitives.Node._from_struct(self, bin_str)
        return n
    
    def nodes(self):
        """Returns a list of all the nodes currently in the database.

        Parameters
        ----------
        None

        Returns
        -------
        A list of vgraph Node objects"""
        offset = 0
        nodes = []
        while True:
            try:
                node = self._node_map.read(offset)
                if node:
                    nodes.append(primitives.Node._from_struct(self, node))
                offset +=1
            except gexceptions.NotInDBError:
                break
        return nodes
    
    def delete_node(self, node):
        """Delete a node from the database.

        Parameters
        ----------
        node: the node object to be deleted

        Returns
        -------
        None"""
        self.batch_delete_edges(node)
        self._node_map.remove(node.id)

    def edge(self, edge_id):
        """Searches for an edge based on edge ID.  If no edge exists,
        a NotInDBError will be thrown.

        Parameters
        ----------
        edge_id: an integer edge ID

        Returns
        -------
        A vgraph Edge object"""
        bin_str = self._edge_map.read(edge_id)
        if not bin_str:
            return None
        e = primitives.Edge._from_struct(self, edge_id, bin_str)
        return e

    def batch_delete_edges(self, node):
        """Normally, during the deletion process of an edge, the preceding
        edge is rewired to point at the edge that follows the deleted edge
        and vice versa. If the caller knows every edge on the node will be 
        deleted, this is a pointless step and can be skipped.

        WARNING: only call this if you are *certain* you want every edge on
        the node to be deleted.

        Parameters
        ----------
        node: the node object whose edges are to be deleted

        Returns
        -------
        None"""
        for e in node.edges():
            self._edge_map.remove(e.id)

    def delete_edge(self, edge):
        """Delete an edge from the database.

        Parameters
        ----------
        edge: the edge object to be deleted

        Returns
        -------
        None"""
        id_num = edge.id
        node_1 = edge.node_1
        if node_1.get_first_edge_offset() == id_num and node_1.get_last_edge_offset() == id_num:
            offset = self._edge_map.get_next_id()
            node_1._set_first_edge_offset(offset)
            node_1._set_last_edge_offset(offset)
            self._node_map.write(node_1.id, node_1.label, node_1._to_struct(),
                                     new=False)
        elif node_1.get_first_edge_offset() == id_num:
            offset = edge.get_next_edge_offset()
            node_1._set_first_edge_offset(offset)
            self._node_map.write(node_1.id, node_1.label, node_1._to_struct(),
                                     new=False) 
        elif node_1.get_last_edge_offset() == id_num:
            node_1._set_last_edge_offset(edge.get_previous_edge_offset())
            self._node_map.write(node_1.id, node_1.label, node_1._to_struct(),
                                     new=False)
        else:
            previous_edge = self.edge(edge.get_previous_edge_offset())
            next_edge = self.edge(edge.get_next_edge_offset())
            previous_edge._set_next_edge_offset(next_edge.id)
            next_edge._set_previous_edge_offset(previous_edge.id)

            self._edge_map.write(previous_edge.id, previous_edge.label,
                                         previous_edge._to_struct())
            self._edge_map.write(next_edge.id, next_edge.label,
                                         next_edge._to_struct())

        self._edge_map.remove(edge.id)
    
    def __create_connection(self, node, e):
        """A private method that takes a node and an edge object
        and writes them to the Graph's associated memory map.  This
        method handles all the details of updating the bookkeeping
        pointers within each object.

        Parameters
        ----------
        node: a vgraph Node object
        e: an vgraph Edge object

        Returns
        -------
        None"""
        node_last_edge = node.get_last_edge_offset()

        #handle the case where this is the first edge for the node
        if not node.edges():
            e.id = node.get_first_edge_offset()
        else:
            e.id = self._edge_map.get_next_id()

            last_edge = self.edge(node_last_edge)
            last_edge._set_next_edge_offset(e.id)
            self._edge_map.write(last_edge.id, last_edge.label, 
                                 last_edge._to_struct(), new=False)        

        previous_offset = node.get_last_edge_offset()
        node._set_last_edge_offset(e.id)

        e._set_previous_edge_offset(previous_offset)
        e._set_next_edge_offset(e.id)
        self._node_map.write(node.id, node.label, node._to_struct(),
                             new=False)
         
        self._edge_map.write(e.id, e.label, e._to_struct())        
        self._edge_map.allocate()
    
    def connect(self, node_1, node_2, label=None, directed=False, cost=0):
        """Creates an edge between two nodes.  A label for the edge must
        be supplied.  Edges can be directed or undirected and carry a "cost"
        or "weight" parameter useful to many graph algorithms that defaults
        to 0.

        Parameters
        ----------
        node_1: the first vgraph Node object to connect
        node_2: the second vgraph Node object to connect
        label: the label for this edge
        directed: if this is True, a directed edge is created, otherwise
                  the edge is undirected
        cost: the weight of the edge

        Returns
        -------
        A vgraph Edge object"""
        if label is None:
            raise ValueError('Every edge must have a label')
        #two edges are created whether or not the relationship is directed
        #this helps speed up searching but also provides graph algorithms
        #a consistent interface where the node_1 attribute is *always* the
        #source node and the node_2 attribute is *always* the target node
        if not directed:
            e1 = primitives.Edge(self, node_1, node_2, label=label, direction=0,
                            cost=cost)
            e2 = primitives.Edge(self, node_2, node_1, label=label, direction=0,
                            cost=cost)
        else:
            e1 = primitives.Edge(self, node_1, node_2, label=label, direction=2,
                            cost=cost)
            e2 = primitives.Edge(self, node_2, node_1, label=label, direction=1,
                            cost=cost)
        self.__create_connection(node_1, e1)
        self.__create_connection(node_2, e2)
        return e1

    def shutdown(self):
        """Closes all of the memory maps and files associated with this
        Graph instance.  Any further calls to Graph methods will result
        in an exception.

        Parameters
        ----------
        None

        Returns
        -------
        None"""
        self._node_map.close()
        self._edge_map.close()
        
