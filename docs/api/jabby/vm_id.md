# vm_id <Badge type="info" text="number"/>

A unique id specifically to the VM that required it.
Every time a new actor requires jabby, it will increment the VM id.
This is the only way for jabby to differentiate different Luau virtual machines,
which is necessary to allow jabby to view into other actors.
