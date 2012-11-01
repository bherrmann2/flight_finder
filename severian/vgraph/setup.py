from distutils.core import setup

setup(
    name='vgraph',
    version='0.1',
    author='Aaron Brenzel',
    url='http://www.github.com/aaronbrenzel',
    author_email='aaronbrenzel@gmail.com',
    description='Python-based persistent store for graph structures and analysis',
    packages=['vgraph', 'vgraph.data', 'vgraph.graph', 'vgraph.algorithms', 'vgraph.data.index'],
    license='MIT',
    package_data={'':['README.txt', 'LICENSE.txt']},
)
