#! /usr/bin/env python

import basic
from collections import defaultdict

def _default_factory():
    return None

def _tarjan_connect(node, index, stack, visited, results):
    """Determines if the node is part of a strongly connected
    component.
    
    NOTE: has the side effect of increasing the value of the index by 1
    as well as pushing the node onto the referenced stack
    
    Parameters
    ----------
    node: the node on which to recurse the depth first search
    index: effectively the current depth of the DFS
    stack: a LIFO list of visited nodes
    visted: a lookup table to store the index and low link attrs of each node
    results: the results dictionary to be returned to the caller of tarjan_sccs"""
    
    visited[node][0] = index
    #the first element is the DFS index, the second is the "low link"
    visited[node].append(index)
    index += 1
    stack.insert(0, node)
    for edge in node.edges(incoming=False, outgoing=True):
        if not visited[edge.node_2]:
            visited[edge.node_2] = [0]
            _tarjan_connect(edge.node_2, index, stack, visited, results)
            visited[node][1] = min(visited[node][1], visited[edge.node_2][1])
        else:
            visited[node][1] = min(visited[node][1], visited[edge.node_2][0])
            
    if visited[node][1] == visited[node][0]:
        results[node] = []
        other_node = stack.pop(0)
        while visited[other_node][1] >= visited[node][1]:
            results[node].append(other_node)
            if not stack:
                break
            other_node = stack.pop(0)
        #stack.insert(0, other_node)

def tarjan_sccs(graph=None, source=None):
    """Implements Tarjan's algorithm for finding strongly connected
    components in a graph.  Either one of "graph" or "source" parameters
    must be not None.  If a graph is supplied, strongly connected components
    will be computed over all nodes.  If a source node is supplied, only
    nodes in its subgraph will be used.
    
    Parameters
    ----------
    graph: a valid vgraph Graph object
    source: a valid vgraph Node object
    
    Returns
    -------
    a dictionary of strongly connected components"""
    
    if graph:
        nodes = graph.nodes()
    elif source:
        nodes = basic.BFS(source)
    else:
        raise ValueError('Must supply either a graph or node object')
        
    index = 0
    stack = []
    results = {}
    visited = defaultdict(_default_factory)
    
    for n in nodes:
        if not visited[n]:
            visited[n] = [0]
            _tarjan_connect(n, index, stack, visited, results)
    
    return results
