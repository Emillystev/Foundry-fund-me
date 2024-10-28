-include .env

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(RPC_URL_SEPOLIA) --private-key $(PRIVATE_KEY_MINE) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv


.PHONY: all test clean deploy fund help install snapshot format anvil zktest

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

zk-anvil :; npx zksync-cli dev start

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy-zk:
	forge create src/FundMe.sol:FundMe --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args $(shell forge create test/mock/MockV3Aggregator.sol:MockV3Aggregator --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args 8 200000000000 --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --legacy --zksync

deploy-sepolia:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)