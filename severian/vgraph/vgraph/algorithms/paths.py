#! /usr/bin/env python
import basic
import heapq

def _dijkstra_reconstruct(previous, source, target):
    path = []
    u = target
    try:
        while previous[u]:
            path.append(u)
            u = previous[u]
    except:
        pass
    path.append(source)
    path.reverse()
    return path

def dijkstra(source, target=None):
    """Implements Dijsktra's algorithm for finding the shortest distance
    between a source node and every node it is connected to.

    If a target is supplied, then a reconstructed path from the source
    to the target will be returned as a list of nodes.  Otherwise, a
    dictionary with connected nodes as the keys and cumulative distance
    as the values will be returned.

    Parameters
    ----------
    source: the node to find shortest paths from
    target: the goal node to find a path to

    Returns
    -------
    A list of nodes OR a dictionary of nodes"""
    everything = basic.BFS(source)
    dist = []
    visited = set()
    results = {}
    previous = {}
    initial_entry = (0, source)
    heapq.heappush(dist, (0, source))
    heap_lookup = {}
    heap_lookup[source] = initial_entry
    for node in everything:
        if node != source:
            entry = (float('inf'), node)
            heapq.heappush(dist, entry)
            #use a lookup table to keep track of the heap entry for each node
            heap_lookup[node] = entry
    while dist:
        u = heapq.heappop(dist)
        if target:
            if u[1] == target:
                return _dijkstra_reconstruct(previous, source, target)
        if u[0] == float('inf'):
            break
        if u[1] in visited:
            continue
        for edge in u[1].edges():
            other_node = edge.node_2
            if other_node in visited:
                continue
            alt = heap_lookup[u[1]][0] + edge.cost
            if alt < heap_lookup[other_node][0]:
                entry = (alt, other_node)
                #since the default entry is infinity, why bother deleting it?
                #we know the item we push in will always be smaller
                heapq.heappush(dist, entry)
                #update the lookup table to the new entry
                heap_lookup[other_node] = entry
                previous[other_node] = u[1]
        visited.add(u[1])
    for h in heap_lookup:
        results[h] = heap_lookup[h][0]
    if target:
        return []
    return results    