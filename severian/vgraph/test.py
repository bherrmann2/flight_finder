import hotshot, hotshot.stats
from vgraph import graph
from vgraph.algorithms import paths
from vgraph.algorithms import basic
from vgraph.algorithms.connected_components import tarjan_sccs
from vgraph.algorithms.sort import topological

def test1():
    g = graph.Graph('test')
    for i in xrange(0,5000):
        g.create_node('gg', indexed=False)

def test2():
    g = graph.Graph('test')
    for i in xrange(0,5000):
        g.node(node_id=0)

profile = hotshot.Profile('profile.txt')
profile.runcall(test1)
profile.close()

stats = hotshot.stats.load("profile.txt")
stats.strip_dirs()
stats.sort_stats('cumulative')
stats.print_stats(20)

profile = hotshot.Profile('profile2.txt')
profile.runcall(test2)
profile.close()

stats = hotshot.stats.load("profile2.txt")
stats.strip_dirs()
stats.sort_stats('cumulative')
stats.print_stats(20)

##g = graph.Graph('path')
##nodes = []
##for x in xrange(6):
##    nodes.append(g.create_node(label=str(x)))
###[0,1,2,3,4,5]
##g.connect(nodes[0], nodes[1], label='path', cost=7)
##g.connect(nodes[0], nodes[2], label='path', cost=9)
##g.connect(nodes[0], nodes[5], label='path', cost=14)
##g.connect(nodes[1], nodes[2], label='path', cost=10)
##g.connect(nodes[1], nodes[3], label='path', cost=15)
##g.connect(nodes[2], nodes[3], label='path', cost=11)
##g.connect(nodes[2], nodes[5], label='path', cost=2)
##g.connect(nodes[3], nodes[4], label='path', cost=6)
##g.connect(nodes[4], nodes[5], label='path', cost=9)
##results = algorithms.paths.dijkstra(g.node(0))
##results2 = algorithms.paths.dijkstra(g.node(0), g.node(5))

#g_cycle = graph.Graph('topo')
#g_no_cycle = graph.Graph('toponc')
##nodes = [g.create_node(label='scc1'), g.create_node(label='scc2'),
##         g.create_node(label='scc3'), g.create_node(label='scc4'),
##         g.create_node(label='scc5'), g.create_node(label='scc6')]
##

##g.connect(nodes[0], nodes[1], label='scc1', directed=True)
##g.connect(nodes[1], nodes[2], label='scc1', directed=True)
##g.connect(nodes[2], nodes[0], label='scc1', directed=True)
##g.connect(nodes[2], nodes[3], label='no_scc', directed=True)
##g.connect(nodes[3], nodes[4], label='scc2', directed=True)
##g.connect(nodes[4], nodes[5], label='scc2', directed=True)
##g.connect(nodes[5], nodes[3], label='scc2', directed=True)
##results = tarjan_sccs(g)
