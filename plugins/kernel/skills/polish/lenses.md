# Finding the passes a stack adds

```pseudo
available_skills
    | where name ~ "*:polish"
    | where name !~ "kernel:polish"
    | where skill's technology context matches current task
    | parallel Skill

-> "Lenses loaded: [names]."
```

If no stack lens is found, apply passes using universal standards only.

