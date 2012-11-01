from vgraph.graph import Graph
g = Graph('test')
n1 = g.create_node('n1')
n2 = g.create_node('n2')
n3 = g.create_node('n3')
g.connect(n1,n2,label='test')
g.connect(n1,n3,label='test')
g.connect(n2,n3,label='test')