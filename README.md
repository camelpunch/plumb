# Plumb

This project is in its early stages of experimentation and doesn't do much yet.

## Running the tests

`rake -T` shows all the available options. `rake` on its own runs just the unit and acceptance tests. Integration tests (tests that hit services) are excluded, as they're least likely to change and take a long time.

## Running the example

Download and run [CCMenu](http://sourceforge.net/projects/ccmenu/files/CCMenu/)

Then start the server:
```bash
foreman start
```

Leave this running, then:
```bash
example/run
```
Edit CCMenu preferences, and add all builds from http://localhost:3000

Now run:
```bash
example/run 1 # 1 denotes the exit code from the build
```
CCMenu should show a red build.

That's as far as this project has got right now.

## Design

### Kick off

User creates pipeline JSON config file, like:

```javascript
{
  order: [
    // step 1
    [
      // step 1a - parallel with step 1b
      {
        "name": "unit-test", // names must be unique
        "repository_url": "/some/place.git",
        "script": "rake units"
      },

      // step 2b - parallel with step 1a
      {
        "name": "another-type-of-unit-test-running-in-parallel",
        "repository_url": "/some/other/place.git",
        "script": "rake units"
      }
    ],

    // step 2
    [
      // single build
      {
        "name": "stage-two-perhaps-an-integration-test",
        "repository_url": "/some/place.git",
        "script": "rake integration"
      }
    ],

    // step 3
    [
      // single build
      {
        "name": "final-deployment",
        "repository_url": "/some/place.git",
        "script": "cap deploy"
      }
    ]
  ]
}
```

Something regularly sends this config into the pipeline processor (currently
STDIN). This thing needs to know whether there have been new changes to any of
the repositories.

### Pipeline

Enqueues everything into the waiting queue, in order.

### Waiting queue runner

- get an item
- do I have builds to run before this item?
    - no: move item to immediate build queue
    - yes:
        - have all of the builds to run before the current item passed?
            - yes: move item to immediate build queue
            - no: leave item in queue


There is one immediate build queue (per architecture), anything in it should be
run immediately.

### Process single build in immediate build queue

- run script
- did I pass?
    - no: notify of failure
    - yes:
        - store into builds that have passed
        - did previous build for this job fail?
            - yes: notify of success


build schema:

- pipeline ID
- job ID
- pipeline run ID
- sibling build IDs
- commit SHAs
- start time
- end time
- success boolean
