#! /usr/bin/env python

def _depth_iter(source, explored, results, outgoing_only=False):
    incom = not outgoing_only
    explored.add(source)
    results.append(source)
    for e in source.edges(incoming=incom):
        next_node = e.node_2
        if not next_node in explored:
            _depth_iter(next_node, explored, results, outgoing_only=outgoing_only)
    return explored

def DFS(source, outgoing_only=False):
    """Performs a depth first search beginning at a source node.  Optionally,
    this function can be made to only search for outgoing edges, which is
    useful in some applications.

    Parameters
    ----------
    source: the source node to begin the search from
    outgoing_only: a boolean specifying whether to only follow outgoing edges

    Returns
    -------
    List of vgraph Node objects"""
    incom = not outgoing_only
    explored = set()
    explored.add(source)
    results = []
    results.append(source)
    for e in source.edges(incoming=incom):
        next_node = e.node_2
        if not next_node in explored:
            _depth_iter(next_node, explored, results, outgoing_only=outgoing_only)
    return results

def BFS(source, outgoing_only=False):
    """Performs a breadth first search beginning at a source node.
    
    Parameters
    ----------
    source: the source node to begin the search from
    
    Returns
    -------
    List of vgraph Node objects"""
    incom = not outgoing_only
    queue = []
    marked = set()
    queue.append(source)
    marked.add(source)
    results = []
    results.append(source)
    while queue:
        v = queue.pop()
        for e in v.edges(incoming=incom):
            next_node = e.node_2
            if next_node not in marked:
                marked.add(next_node)
                queue.append(next_node)
                results.append(next_node)
    return results
