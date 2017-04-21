# Scope Runner
ScopeRunner Runs RunScope Scopes. Run your RunScope scopes with ScopeRunner!

That is to say, ScopeRunner allows you to run (so far a limited subset of)
RunScope API tests, that have been exported to JSON via RunScope's export feature,
from your local development environment, without the need for a connection to
RunScope's servers.

ScopeRunner has been developed in a rush to support very simple RunScope workflows,
it is far from feature-complete and it may not work for you. If you would like to
give it a try, take a look at `scope_runner.rb` for the basics of how to use the
library. If you save your exported RunScope API tests as `scopes.json`, and run
`scope_runner.rb`, it will try to run some of your scopes for you. If you have
any initial variables that you need to set, you can do so by creating a file
`env.yaml`, that should look like:

```yaml
vars:
  var_one: value one
  you_get: the idea
```

There are no tests. It's a bit shaky.

![caveat emptor](http://images1.tickld.com/live/1380405.gif)

Viel spaß!
