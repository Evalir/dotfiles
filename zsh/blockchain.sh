# These must be providedd locally but are not pushed due to sensitive info
source "$(dirname "$0")/rpc.sh"

# ec recover util
export ECRECOVER=0x0000000000000000000000000000000000000001

###############
# RPC Helpers #
###############

# block explorer urls for the explore() helper
export ETHEREUM_BLOCK_EXPLORER=https://etherscan.io
export GOERLI_BLOCK_EXPLORER=https://goerli.etherscan.io
export POLYGON_BLOCK_EXPLORER=https://polygonscan.com
export MUMBAI_BLOCK_EXPLORER=https://mumbai.polygonscan.com
export OPTIMISM_BLOCK_EXPLORER=https://optimistic.etherscan.io
export OPTIMISM_GOERLI_BLOCK_EXPLORER=https://goerli-optimism.etherscan.io/
export ARBITRUM_BLOCK_EXPLORER=https://arbiscan.io
export ARBITRUM_NOVA_BLOCK_EXPLORER=https://nova.arbiscan.io
export ARBITRUM_GOERLI_BLOCK_EXPLORER=https://goerli.arbiscan.io
export AVALANCHE_BLOCK_EXPLORER=https://snowtrace.io
export FUJI_BLOCK_EXPLORER=https://testnet.snowtrace.io
export BSC_BLOCK_EXPLORER=https://bscscan.com
export BSC_TEST_BLOCK_EXPLORER=https://testnet.bscscan.com
export GNOSIS_BLOCK_EXPLORER=https://gnosisscan.io
export KLAYTN_BLOCK_EXPLORER=https://scope.klaytn.com
export BAOBAB_BLOCK_EXPLORER=https://baobab.scope.klaytn.com

# Set ETH_RPC_URL and ETHERSCAN_API_KEY (the defaults that forge + cast read) based on chain name
# Uses values sourced from rpcs.sh
chain() {
    chain_name=$1
    if [[ "$1" == "polygon" ]]
    then
        export ETH_RPC_URL=$POLYGON_RPC_URL
        export ETHERSCAN_API_KEY=$POLYGON_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$POLYGON_BLOCK_EXPLORER
    elif [[ "$1" == "mumbai" ]]
    then
        export ETH_RPC_URL=$MUMBAI_RPC_URL
        export ETHERSCAN_API_KEY=$POLYGON_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$MUMBAI_BLOCK_EXPLORER
    
    elif [[ "$1" == "goerli" ]]
    then
        export ETH_RPC_URL=$GOERLI_RPC_URL
        export ETHERSCAN_API_KEY=$ETHEREUM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$GOERLI_BLOCK_EXPLORER
    elif [[ "$1" == "arbitrum" ]]
    then
        export ETH_RPC_URL=$ARBITRUM_RPC_URL
        export ETHERSCAN_API_KEY=$ARBITRUM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$ARBITRUM_BLOCK_EXPLORER
    elif [[ "$1" == "arbitrum-nova" ]]
    then
        export ETH_RPC_URL=$ARBITRUM_NOVA_RPC_URL
        export ETHERSCAN_API_KEY=$ARBITRUM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$ARBITRUM_NOVA_BLOCK_EXPLORER
    elif [[ "$1" == "arbitrum-goerli" ]]
    then
        export ETH_RPC_URL=$ARBITRUM_GOERLI_RPC_URL
        export ETHERSCAN_API_KEY=$ARBITRUM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$ARBITRUM_GOERLI_BLOCK_EXPLORER
    elif [[ "$1" == "optimism" ]]
    then
        export ETH_RPC_URL=$OPTIMISM_RPC_URL
        export ETHERSCAN_API_KEY=$OPTIMISM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$OPTIMISM_BLOCK_EXPLORER
        
    elif [[ "$1" == "optimism-goerli" ]]
    then
        export ETH_RPC_URL=$OPTIMISM_GOERLI_RPC_URL
        export ETHERSCAN_API_KEY=$OPTIMISM_ETHERSCAN_API_KEY
        export BLOCK_EXPLORER=$OPTIMISM_GOERLI_BLOCK_EXPLORER
    elif [[ "$1" == "klaytn" ]]
    then
        export ETH_RPC_URL=$KLAYTN_RPC_URL
        export BLOCK_EXPLORER=$KLAYTN_BLOCK_EXPLORER
    elif [[ "$1" == "baobab" ]]
    then
        export ETH_RPC_URL=$BAOBAB_RPC_URL
        export BLOCK_EXPLORER=$BAOBAB_BLOCK_EXPLORER
    elif [[ "$1" == "bsc" ]]
    then
        export ETH_RPC_URL=$BSC_RPC_URL
        export BLOCK_EXPLORER=$BSC_BLOCK_EXPLORER
    elif [[ "$1" == "bsc-test" ]]
    then
        export ETH_RPC_URL=$BSC_TEST_RPC_URL
        export BLOCK_EXPLORER=$BSC_TEST_BLOCK_EXPLORER
    elif [[ "$1" == "anvil" ]]
    then
        export ETH_RPC_URL=$ANVIL_RPC_URL

    elif [[ "$1" == "avalanche" ]]
    then 
        export ETH_RPC_URL=$AVALANCHE_RPC_URL
        export BLOCK_EXPLORER=$AVALANCHE_BLOCK_EXPLORER
    elif [[ "$1" == "fuji" ]]
    then
        export ETH_RPC_URL=$FUJI_RPC_URL
        export BLOCK_EXPLORER=$FUJI_BLOCK_EXPLORER
    else
        # fallback is mainnet
        export chain_name="mainnet"
        export ETHERSCAN_API_KEY=$ETHEREUM_ETHERSCAN_API_KEY
        export ETH_RPC_URL=$ETHEREUM_RPC_URL
        export BLOCK_EXPLORER=$ETHEREUM_BLOCK_EXPLORER
    fi
}

# View an address or transaction hash on the block explorer of the current active chain (configured with chain() command)
# macOS only
explore() {
    if [[ ${#1} -eq 42 ]]; then 
        arg="${BLOCK_EXPLORER}/address/$1"
    else
        arg="${BLOCK_EXPLORER}/tx/$1"
    fi
    open -n $arg
}

echo "Blockchain utils sourced"
