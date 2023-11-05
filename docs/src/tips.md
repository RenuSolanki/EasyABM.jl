
!!! warn
    Avoid modifying any mutable model properties except through utility functions provided by EasyABM. For example, shuffling the list `model.agents` may lead to errorneous results. Immutable properties like `model.tick` must also be not modified as they are only for internal use in EasyABM.



!!! tip "Performance Tips"
    * Avoid using global variables (its a general tip for Julia users)
    * In EasyABM the types of model properties, patch properties, nodes/edges properties, and agents properties (other than position) are not declared while defining the model. Therefore, if the user wishes to make code a bit more performant, such properties can be annotated with their types in the `step_rule!` function.
