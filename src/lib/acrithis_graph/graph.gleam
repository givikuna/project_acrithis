import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}

pub type GraphVertex(a) {
  GraphVertex(id: String, value: a)
}

pub type Graph(a) {
  Graph(
    vertices: Dict(String, GraphVertex(a)),
    edges: Dict(String, List(String)),
  )
}

pub fn new() -> Graph(a) {
  Graph(vertices: dict.new(), edges: dict.new())
}

pub fn add_vertex(graph: Graph(a), id: String, value: a) -> Graph(a) {
  let vertex: GraphVertex(a) = GraphVertex(id: id, value: value)
  let new_vertices: Dict(String, GraphVertex(a)) =
    dict.insert(graph.vertices, id, vertex)

  let new_edges: Dict(String, List(String)) = case
    dict.has_key(graph.edges, id)
  {
    True -> graph.edges
    False -> dict.insert(graph.edges, id, [])
  }

  Graph(vertices: new_vertices, edges: new_edges)
}

pub fn add_edge(
  graph: Graph(a),
  source_id: String,
  target_id: String,
) -> Result(Graph(a), Nil) {
  use _ <- result.try(dict.get(graph.vertices, source_id))
  use _ <- result.try(dict.get(graph.vertices, target_id))

  let current_edges = case dict.get(graph.edges, source_id) {
    Ok(edges) -> edges
    Error(_) -> []
  }

  let new_edges =
    dict.insert(graph.edges, source_id, [target_id, ..current_edges])
  Ok(Graph(..graph, edges: new_edges))
}

pub fn get_vertex(graph: Graph(a), id: String) -> Result(a, Nil) {
  let vertex_result: Result(GraphVertex(a), Nil) = dict.get(graph.vertices, id)

  case vertex_result {
    Ok(vertex) -> Ok(vertex.value)
    Error(Nil) -> Error(Nil)
  }
}

pub fn get_dependencies(
  graph: Graph(a),
  id: String,
) -> Result(List(String), Nil) {
  let has_node: Bool = dict.has_key(graph.vertices, id)

  case has_node {
    False -> Error(Nil)
    True -> {
      let edges: List(String) = case dict.get(graph.edges, id) {
        Ok(e) -> e
        Error(_) -> []
      }
      Ok(edges)
    }
  }
}

pub fn contains_vertex(graph: Graph(a), id: String) -> Bool {
  let exists: Bool = dict.has_key(graph.vertices, id)
  exists
}

pub fn vertex_count(graph: Graph(a)) -> Int {
  let size: Int = dict.size(graph.vertices)
  size
}

pub fn has_cycle(graph: Graph(a)) -> Bool {
  let vertex_ids: List(String) = dict.keys(graph.vertices)
  let initial_visited: Set(String) = set.new()
  let initial_stack: Set(String) = set.new()

  let cycle_found: Bool =
    check_cycles_dfs(vertex_ids, graph, initial_visited, initial_stack)

  cycle_found
}

fn check_cycles_dfs(
  nodes_to_visit: List(String),
  graph: Graph(a),
  visited: Set(String),
  recursion_stack: Set(String),
) -> Bool {
  case nodes_to_visit {
    [] -> False
    [current_node, ..rest] -> {
      let is_in_stack: Bool = set.contains(recursion_stack, current_node)

      case is_in_stack {
        True -> True
        False -> {
          let is_visited: Bool = set.contains(visited, current_node)

          case is_visited {
            True -> check_cycles_dfs(rest, graph, visited, recursion_stack)
            False -> {
              let new_stack: Set(String) =
                set.insert(recursion_stack, current_node)
              let new_visited: Set(String) = set.insert(visited, current_node)

              let neighbors: List(String) = case
                dict.get(graph.edges, current_node)
              {
                Ok(edges) -> edges
                Error(_) -> []
              }

              let has_child_cycle: Bool =
                check_cycles_dfs(neighbors, graph, new_visited, new_stack)

              case has_child_cycle {
                True -> True
                False -> {
                  let popped_stack: Set(String) =
                    set.delete(new_stack, current_node)
                  check_cycles_dfs(rest, graph, new_visited, popped_stack)
                }
              }
            }
          }
        }
      }
    }
  }
}
