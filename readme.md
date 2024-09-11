# Participation token

### About this project

- [Project Description](ParticipationToken.md)

## Usage

You'll need Foundry/Forge for testing, and SOLC 0.8.26+ which should be used with `--via-ir` param to enable experimental feauture `require(condition, error())`

### Setup

we use Foundry for testing and deployment
To install Foundry: <br>

1. `$ curl -L https://foundry.paradigm.xyz | bash`
2. restart terminal
3. `$ foundryup`
4. `$ cargo install --git https://github.com/gakonst/foundry --bin forge --locked`

more details on installation here: https://github.com/foundry-rs/foundry

### Tests

Tests are placed in the **/tests** folders and written in Solidity.

To run tests: `forge test -vv --via-ir`
