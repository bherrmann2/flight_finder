ABOUT:

vgraph is a pure Python graph database.  It persists files to disk and uses a binary data file format.

It is not currently intended to be a competitor to enterprise offerings such as neo4j or hypergraph in either speed or robustness.  For the moment, it is a research project into the viability of using Python for database design and prototyping, and as an intellectual challenge for myself.

As of right now, the file format is basic and the indexing is not implemented in a hugely sophisticated way (it basically mimics the Python dictionary implementation, except on disk instead of in memory).  I do use this in production for smaller projects, but I have not attempted to scale it to millions of nodes yet.

The directory structure looks like this:

vgraph
      ----> data  - the implementations of the database file format
            ----> index - the implementation of the label indexing capabilities
      ----> algorithms - where the algorithms live, only fairly basic ones are implemented so far
      ----> graph - the user-facing Graph object lives here, you interact with the database itself using this object

A quick run of the code might look like this:

from vgraph.graph import Graph
from vgraph.algorithms.basic import BFS

>>> g = Graph('mygraph')
>>> node_1 = g.create_node(label='test1')
>>> node_2 = g.create_node(label='test2')
>>> g.connect(node_1, node_2, label='new edge')

>>> BFS(node_1)
[<node: 'test1'>, <node: 'test2'>]
>>> BFS(node_2)
[<node: 'test2'>, <node: 'test1'>]
