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
  StatesChange(@respo.RespoUpdateState)
}

///|
impl @respo_node.RespoAction for ActionOp with build_states_action(cursor, a) {
  StatesChange({ cursor, data: a.map(ToJson::to_json) })
}

///|
impl Show for ActionOp with output(self, logger) -> Unit {
  let s = match self {
    StatesChange(states) =>
      "StatesChange(\{states.cursor}  \{states.data.to_json()})"
  }
  logger.write_string(s)
}

///|
fn Store::get_states(self : Store) -> @respo.RespoStatesTree {
  self.states
}

///| TODO mutation might break memoization infuture
fn update(self : Store, op : ActionOp) -> Unit {
  match op {
    StatesChange(states) => self.states.set_in_mut(states)
  }
}

///|
impl Show for Store with output(self, logger) -> Unit {
  logger.write_string(self.to_json().stringify(indent=2))
}
