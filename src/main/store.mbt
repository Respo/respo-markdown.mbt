///|
struct Store {
  tasks : Array[Task]
  states : @respo.RespoStatesTree
} derive(ToJson, @json.FromJson)

///|
impl Default for Store with default() -> Store {
  { tasks: [], states: @respo.RespoStatesTree::default() }
}

///|
struct Task {
  id : String
  done : Bool
  content : String
  time : Double
} derive(Default, Eq, Hash, ToJson, @json.FromJson)

///|
enum ActionOp {
  Noop
  StatesChange(@respo.RespoUpdateState)
}

///|
impl Default for ActionOp with default() -> ActionOp {
  Noop
}

///|
impl @respo_node.RespoAction for ActionOp with build_states_action(cursor, a) {
  StatesChange({ cursor, data: a.map(fn(x) { x.to_json() }) })
}

///|
impl Show for ActionOp with output(self, logger) -> Unit {
  let s = match self {
    Noop => "Noop"
    StatesChange(states) =>
      "StatesChange(\{states.cursor}  \{states.data.to_json()})"
    // Intent(_intent) => "Intent(...)"

  }
  logger.write_string(s)
}

///|
fn get_states(self : Store) -> @respo.RespoStatesTree {
  self.states
}

///| TODO mutation might break memoization infuture
fn update(self : Store, op : ActionOp) -> Unit {
  match op {
    StatesChange(states) => self.states.set_in_mut(states)
    _ => ()
  }
}

///|
impl Show for Store with output(self, logger) -> Unit {
  logger.write_string(self.to_json().stringify(indent=2))
}
