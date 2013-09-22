#!/usr/bin/env ruby
# Tai Sakuma <sakuma@fnal.gov>

require 'ddlcallbacks_listeners'
require 'GeometryManager'

require 'gratr'


##____________________________________________________________________________||
def subgraph_from(graph, from)
  # tree from from
  hashPredecessorBFSTreeFrom = graph.bfs_tree_from_vertex(from)
  arrayBFSTreeFrom = hashPredecessorBFSTreeFrom.collect { |k, v| k }.uniq
  arrayBFSTreeFrom << from

  graphFrom = GRATR::Digraph.new
  graph.edges.each { |a| graphFrom.add_edge!(a.source, a.target) if arrayBFSTreeFrom.include?(a.source) and arrayBFSTreeFrom.include?(a.target) }

  graphFrom
end

##____________________________________________________________________________||
def subgraph_from_depth(graph, from, depth = -1)

  graphFrom = subgraph_from(graph, from)
  return graphFrom if depth < 0

  simple_weight = Proc.new {|e| 1}
  distance, path = graphFrom.shortest_path(from, simple_weight)

  graphFromDepth = GRATR::Digraph.new
  graphFrom.edges.each { |a| graphFromDepth.add_edge!(a.source, a.target) if distance[a.target] <= depth }
  graphFromDepth
end

##____________________________________________________________________________||
def subgraph_from_to(graph, from, to)
  def buildLocalGraph graph, localGraph, from, to
    to.each do |child|
      parents = graph.adjacent(child, {:direction => :in})
      parents.each do |parent|
        localGraph.add_edge!(parent, child)
      end
      parents.reject! { |p| p == from }
      buildLocalGraph(graph, localGraph, from, parents)
    end
    localGraph
  end
  localGraph = GRATR::Digraph.new
  buildLocalGraph graph, localGraph, from, to
end

##____________________________________________________________________________||
def topsort_from_depth(graph, from, depth = -1)
  graphFrom = subgraph_from_depth(graph, from, depth)

  # topological sort from from
  graphFrom.size > 0 ? graphFrom.topsort(from) : [from]
end

##____________________________________________________________________________||
def topsort_from_to graph, from, to
  localGraph = subgraph_from_to(graph, from, to)
  localGraph.size > 0 ? localGraph.topsort(from) : [from]
end

##____________________________________________________________________________||
def readXMLFiles(xmlfileList, callBacks, geometryManager)
  xmlfileList.each do |file| 
    p file
    geometryManager.xmlFilePath = file
    REXML::Document.parse_stream(File.new(file), callBacks)
  end
end

##____________________________________________________________________________||
def buildDDLCallBacks(geometryManager)

  materialSectionListener = SectionWithPartListener.new("MaterialSection", geometryManager)
  rotationSectionListener = RotationSectionListener.new(geometryManager)
  solidSectionListener = SectionWithPartListener.new("SolidSection", geometryManager)
  logicalPartSectionListener = SectionWithPartListener.new("LogicalPartSection", geometryManager)
  posPartSectionListener = SectionWithPartListener.new("PosPartSection", geometryManager)

  mainListenersDispatcher = HashListenersDispatcher.new
  mainListenersDispatcher.add_listner('MaterialSection', materialSectionListener)
  mainListenersDispatcher.add_listner('RotationSection', rotationSectionListener)
  mainListenersDispatcher.add_listner('SolidSection', solidSectionListener)
  mainListenersDispatcher.add_listner('LogicalPartSection', logicalPartSectionListener)
  mainListenersDispatcher.add_listner('PosPartSection', posPartSectionListener)

  callBacks = DDLCallbacks.new
  callBacks.listenersDispatcher = mainListenersDispatcher
  callBacks
end

##____________________________________________________________________________||
