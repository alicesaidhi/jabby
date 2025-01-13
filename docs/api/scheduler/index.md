# Scheduler

The scheduler is an interface for jabby into a generic ECS scheduler. Schedulers
expect the common notion that logic is executed within systems, not out of order.
Systems are optionally also sorted into phases, which add collapsible categories
in the [scheduler applet](../applets/scheduler.md).

## API

- [get_system_data](./get_system_data.md)
- [register_system](./register_system.md)
- [remove_system](./remove_system.md)
- [run](./run.md)
- [set_system_data](./set_system_data.md)
