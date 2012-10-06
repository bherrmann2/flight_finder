import structs, gexceptions
import re

class GraphObject(object):
    __g_attrs__ = set()
    def __eq__(self, other):
        return self.id == other.id
    
    def __ne__(self, other):
        return self.id != other.id
    
    def __hash__(self):
        return self.id

class Node(GraphObject):
    __g_attrs__ = set(['id', 'label'])
    def __init__(self, graphref, label=''):
        """Initializes a new vgraph Node object.  All Node objects
        carry a reference to the graph that they came from so that
        traversals can be carried out without the user having to pass
        graph references around in many cases.

        Parameters
        ----------
        graphref: a reference to a vgraph Graph object
        label: the label for the node"""
        self.__graph = graphref
        self.id = 0 # temp for testing
        self.label = label
        self.__first_edge = 0
        self.__last_edge = 0

    @classmethod
    def _from_struct(self, graphref, bin_str):
        """Reconstructs a Node object from a struct of binary data

        Parameters
        ----------
        graphref: a reference to a vgraph Graph object
        bin_str: a string of binary data

        Returns
        -------
        A vgraph Node object"""
        node_tuple = structs.unpack_node(bin_str)
        n = Node(graphref)
        n.id = node_tuple[0]
        n.label = re.sub(r'\x00', '', node_tuple[1])
        n._set_first_edge_offset(node_tuple[2])
        n._set_last_edge_offset(node_tuple[3])
        return n
    
    def _set_first_edge_offset(self, edge_id):
        self.__first_edge = edge_id
    
    def get_first_edge_offset(self):
        """Returns the offset into the database file where this
        nodes *first* edge can be found.

        IMPORTANT: You should always read the offset using this getter
        rather than using the objects __dict__ or going around the name
        mangling.  The value is updated on each read in case the node's
        underlying data has been changed since object instantiation.

        Parameters
        ----------
        None

        Returns
        -------
        Integer"""
        st = structs.unpack_node(self.__graph._node_map.read(self.id))
        self.__first_edge = st[2]
        return self.__first_edge

    def _set_last_edge_offset(self, edge_id):
        self.__last_edge = edge_id
    
    def get_last_edge_offset(self):
        """Returns the offset into the database file where this
        nodes *last* edge can be found.

        IMPORTANT: You should always read the offset using this getter
        rather than using the objects __dict__ or going around the name
        mangling.  The value is updated on each read in case the node's
        underlying data has been changed since object instantiation.

        Parameters
        ----------
        None

        Returns
        -------
        Integer"""
        st = structs.unpack_node(self.__graph._node_map.read(self.id))
        self.__last_edge = st[3]
        return self.__last_edge
    
    def __repr__(self):
        return '<Node %d: %s>' % (self.id, self.label)
    
    def _to_struct(self):
        """Returns a string of binary data representing this node's
        attributes suitable for writing into a file or memory map.

        Parameters
        ----------
        None

        Returns
        -------
        String"""
        return structs.pack_node(self.id, self.__first_edge, self.__last_edge, label=self.label)
        
    def edges(self, incoming=True, outgoing=True):
        """Get all edges incident to this node.  Edges can be prefiltered
        for incoming or outcoming only using the keyword arguments.  If both
        incoming and outgoing are True, undirected edges will also be returned.

        Parameters
        ----------
        incoming: boolean for whether incoming edges should be returned
        outgoing: boolean for whether outgoing edges should be returned

        Returns
        -------
        List of vgraph Edge objects"""
        edges = []
        try:
            e = self.__graph.edge(self.__first_edge)
        except gexceptions.NotInDBError:
            return edges
        if e:
            if incoming and outgoing:
                edges.append(e)
            elif incoming and not outgoing:
                if e.direction == 1:
                    edges.append(e)
            elif outgoing and not incoming:
                if e.direction == 2:
                    edges.append(e)
            while 1:
                next_offset = e.get_next_edge_offset()
                if next_offset == e.id:
                    break
                e = self.__graph.edge(next_offset)
                if e is None:
                    break
                if incoming and outgoing:
                    edges.append(e)
                elif incoming and not outgoing:
                    if e.direction == 1:
                        edges.append(e)
                elif outgoing and not incoming:
                    if e.direction == 2:
                        edges.append(e)
        return edges
        
class Edge(GraphObject):
    _g_attrs__ = set(['node_1', 'node_2', 'label', 'direction', 'cost'])
    def __init__(self, graphref, node_1, node_2, label='', direction=False,
                 cost=0):
        """Initializes a new vgraph Edge object.  All Edge objects
        carry a reference to the graph that they came from so that
        traversals can be carried out without the user having to pass
        graph references around in many cases.

        Parameters
        ----------
        graphref: a reference to a vgraph Graph object
        node_1: the source node for the edge
        node_2: the target node for the edge
        label: the label for the node
        direction: may be either 0 (undirected), 1 (incoming) or
                   2 (outgoing)
        cost: a weight for the edge, used in some graph algorithms"""
        self.__graph = graphref
        self.node_1 = node_1
        self.node_2 = node_2
        self.label = label
        self.direction = direction
        self.cost = cost
        self.__previous_edge = 0
        self.__next_edge = 0
        self.dirty = False
        
    @classmethod
    def _from_struct(self, graphref, id_num, bin_str):
        """Reconstructs an Edge object from a struct of binary data.

        IMPORTANT: Edge deletion in vgraph is lazy.  When a node is
        deleted, incoming edges are only deleted when a caller attempts
        to access them.  This method has the potential to return an edge
        other than the one requested if the requested edge is discovered 
        to be "dangling" during object creation.

        Parameters
        ----------
        graphref: a reference to a vgraph Graph object
        id_num: the integer ID for this Edge
        bin_str: a string of binary data

        Returns
        -------
        A vgraph Edge object"""
        edge_tuple = structs.unpack_edge(bin_str)
        node_1 = graphref.node(edge_tuple[1])
        node_2 = graphref.node(edge_tuple[2])
        e = Edge(
            graphref,
            node_1,
            node_2,
            label=re.sub(r'\x00', '', edge_tuple[3]),
            direction=edge_tuple[4],
            cost = edge_tuple[0]
        )
        e.id = id_num
        e._set_previous_edge_offset(edge_tuple[5])
        e._set_next_edge_offset(edge_tuple[6])
        if node_2 is None:
            graphref.delete_edge(e)
            if edge_tuple[6] == edge_tuple[5]:
                return []
            return graphref.edge(edge_tuple[6])
        return e
    
    def __repr__(self):
        return '<Edge %d: %s>' % (self.id, self.label)
        
    def _set_previous_edge_offset(self, offset):
        self.__previous_edge = offset
        
    def get_previous_edge_offset(self):
        """Returns the offset into the database file where the
        *previous* edge with the same source node can be found.

        IMPORTANT: You should always read the offset using this getter
        rather than using the objects __dict__ or going around the name
        mangling.  The value is updated on each read in case the node's
        underlying data has been changed since object instantiation.

        Parameters
        ----------
        None

        Returns
        -------
        Integer"""
        st = structs.unpack_edge(self.__graph._edge_map.read(self.id))
        self.__previous_edge = st[5]
        return self.__previous_edge

    def _set_next_edge_offset(self, offset):
        self.__next_edge = offset
        
    def get_next_edge_offset(self):
        """Returns the offset into the database file where the
        *next* edge with the same source node can be found.

        IMPORTANT: You should always read the offset using this getter
        rather than using the objects __dict__ or going around the name
        mangling.  The value is updated on each read in case the node's
        underlying data has been changed since object instantiation.

        Parameters
        ----------
        None

        Returns
        -------
        Integer"""
        st = structs.unpack_edge(self.__graph._edge_map.read(self.id))
        self.__next_edge = st[6]
        return self.__next_edge
    
    def _to_struct(self):
        """Returns a string of binary data representing this edge's
        attributes suitable for writing into a file or memory map.

        Parameters
        ----------
        None

        Returns
        -------
        String"""
        return structs.pack_edge(self.cost, self.node_1.id, self.node_2.id,
                self.__previous_edge, self.__next_edge, label=self.label, direction=self.direction)
