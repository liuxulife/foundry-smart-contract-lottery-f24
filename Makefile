-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :; forge install Cyfrin/foundry-devops --no-commit \
&& forge install smartcontractkit/chainlink-brownie-contracts --no-commit \
&& forge install foundry-rs/forge-std --no-commit \
&& forge install rari-capital/solmate --no-commit

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) \
	--account mycount --broadcast --verify --etherscan-api-key $(ETHERSACN_API_KEY) -vvvv