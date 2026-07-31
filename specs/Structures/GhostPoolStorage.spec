using PoolOriginal as a;
using PoolOptimized as ao;

ghost mapping(address => address) ghostProviderAddress;

ghost mapping(address => address) ghostPoolConfigurator;

ghost mapping(uint => uint) storageOfA;

ghost mapping(uint => uint) storageOfAo;

hook ALL_SSTORE(uint loc, uint value) {
    if (executingContract == a) {
        storageOfA[loc] = value;
    } else if (executingContract == ao) {
        storageOfAo[loc] = value;
    }
}

hook ALL_SLOAD(uint loc) uint value {
    if (executingContract == a) {
        require storageOfA[loc] == value;
    } else if (executingContract == ao) {
        require storageOfAo[loc] == value;
    }
}
