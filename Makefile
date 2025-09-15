-include .env

.PHONY: build test snapshot clean anvil deploy-local deploy-sepolia pay withdraw

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Default network args (local anvil)
NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(PRIVATE_KEY)

# Switch to sepolia if passed
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv
endif

# Compile contracts
build:
	forge build

# Run all tests
test:
	forge test -vvv

# Snapshot gas usage
snapshot:
	forge snapshot

# Remove cache & out
clean:
	forge clean

# Run a local anvil node
anvil:
	anvil

# Deploy locally (default to anvil)
deploy-local:
	forge script script/DeployPayPerView.s.sol:DeployPayPerView \
		$(NETWORK_ARGS)

# Deploy to Sepolia (pass ARGS="--network sepolia")
deploy-sepolia:
	forge script script/DeployPayPerView.s.sol:DeployPayPerView \
		$(NETWORK_ARGS)

# Interactions
pay:
	forge script script/Interactions.s.sol:payPayPerView \
		--sender $(SENDER_ADDRESS) $(NETWORK_ARGS)

withdraw:
	forge script script/Interactions.s.sol:withdrawPayPerView \
		$(NETWORK_ARGS)
