# Time Travel Example


A tiny counter app demonstrating `puer`-based state management and time-travel debugging. This sample is used by developers to test the Time Travel DevTools extension.

- State: `puer` (pure update function + explicit effects; state is a simple counter)
- UI: `puer_flutter` connects the feature to Flutter widgets
- Time travel: `puer_time_travel` records and replays counter actions for the DevTools extension

Run:

```
cd samples/time_travel_example
fvm flutter run
```
