# Installing packages from a private GitHub repository

Clusters can be configured to install packages from a private GitHub repository by settting the __githubAuthenticationToken__ property. If this property is blank only public repositories can be used. If a token is added then public and the private github repo can be used together.

```json
{
    {
    "name": <your pool name>,
    "vmSize": <your pool VM size name>,
    "maxTasksPerNode": <num tasks to allocate to each node>,
    "poolSize": {
        "dedicatedNodes": {
            "min": 2,
            "max": 2
        },
        "lowPriorityNodes": {
            "min": 1,
            "max": 10
        },
        "autoscaleFormula": "QUEUE"
    },
    "rPackages": {
        "cran": [],
        "github": ["<project/some_private_repository>"],
        "githubAuthenticationToken": "<github_authentication_token>"
    },
    "commandLine": []
    }
}
```

_More information regarding github authentication tokens can be found [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)_