typedef Transition<State, Message, Effect> = ({
  State stateBefore,
  Message message,
  State? stateAfter,
  List<Effect> effects,
});
