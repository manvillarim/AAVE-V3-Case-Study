using RegistryOriginal as a;
using RegistryOptimized as ao;


// Mirrors a._addressesProvidersList.length
ghost uint256 ghostArrayLength {
    init_state axiom ghostArrayLength == 0;
    // Canonicity bound: length of a dynamic array fits in uint64
    axiom ghostArrayLength < max_uint64;
}

// Mirrors a._addressesProvidersList[i]
ghost mapping(uint256 => address) ghostArrayElements {
    init_state axiom forall uint256 i. ghostArrayElements[i] == 0;
}


// Track writes to the array length slot (slot 0 of the dynamic array)
hook Sstore a._addressesProvidersList.(offset 0) uint256 newLen (uint256 oldLen) {
    ghostArrayLength = newLen;
}

// Track reads of the array length slot so the solver links ghost ↔ storage
hook Sload uint256 len a._addressesProvidersList.(offset 0) {
    require ghostArrayLength == len;
}

// Track writes to individual array elements
hook Sstore a._addressesProvidersList[INDEX uint256 i] address newVal (address oldVal) {
    ghostArrayElements[i] = newVal;
}

// Track reads of individual array elements
hook Sload address val a._addressesProvidersList[INDEX uint256 i] {
    require ghostArrayElements[i] == val;
}
