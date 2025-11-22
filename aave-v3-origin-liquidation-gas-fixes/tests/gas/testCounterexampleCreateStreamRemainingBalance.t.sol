// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
// Ajuste o caminho de importação conforme a estrutura do seu projeto
import {Collector} from "../../src/contracts/treasury/Collector.sol";

// NÃO PRECISAMOS MAIS DO CONTRATO TestCollector

contract CollectorTest is Test {
    Collector public collector;

    // Endereços do contraexemplo
    address public ADMIN = makeAddr("ADMIN");
    address public RECIPIENT = makeAddr("RECIPIENT");
    address public TOKEN = makeAddr("TOKEN");

    // ID do stream do contraexemplo
    uint256 public constant INITIAL_STREAM_ID = 10001;

    // --- INÍCIO DA CORREÇÃO ---
    /**
     * @notice O contrato Initializable da OpenZeppelin usa o slot 0
     * para rastrear se o contrato foi inicializado.
     * _disableInitializers() define este slot como 255.
     * Nós o usaremos para redefinir o slot para 0.
     */
    bytes32 internal constant INITIALIZABLE_SLOT = bytes32(0);
    // --- FIM DA CORREÇÃO ---


    function setUp() public {
        // 1. Implanta o Collector. Seu construtor irá travar o contrato.
        collector = new Collector(); // <--- MUDANÇA AQUI (voltamos ao original)

        // 2. "Destrava" o contrato para testes usando vm.store
        // Nós reescrevemos o slot 0 de 255 (travado) para 0 (destravado).
        // Isso nos permite chamar initialize() mesmo na implementação direta.
        vm.store(address(collector), INITIALIZABLE_SLOT, bytes32(0));

        // 3. Inicializa o contrato
        // Agora isso vai funcionar!
        vm.prank(ADMIN);
        collector.initialize(INITIAL_STREAM_ID, ADMIN);

        // 4. Concede o papel
        collector.grantRole(collector.FUNDS_ADMIN_ROLE(), ADMIN);
    }

    /**
     * @notice Testa o cenário exato do contraexemplo do Certora.
     * Verifica se o remainingBalance é definido corretamente durante a criação do stream.
     */
    function testCounterexampleCreateStreamRemainingBalance() public {
        // --- 1. Parâmetros do Cenário ---
        uint256 deposit = 1;
        uint256 startTime = block.timestamp + 100;
        uint256 stopTime = startTime + 1; // Duração de 1 segundo

        // --- 2. Ação ---
        vm.prank(ADMIN);
        
        uint256 streamId = collector.createStream(
            RECIPIENT,
            deposit,
            TOKEN,
            startTime,
            stopTime
        );

        // --- 3. Asserções ---
        assertEq(streamId, INITIAL_STREAM_ID, "Stream ID mismatch");
        assertEq(collector.getNextStreamId(), INITIAL_STREAM_ID + 1, "nextStreamId did not increment");

        (
            ,
            address recipient,
            uint256 depositAmount,
            ,
            ,
            ,
            uint256 remainingBalance,
            uint256 ratePerSecond
        ) = collector.getStream(streamId);

        // --- A VERIFICAÇÃO PRINCIPAL DO BUG ---
        assertEq(remainingBalance, deposit, "BUG: remainingBalance was not set to deposit on creation");
        // ----------------------------------------

        assertEq(recipient, RECIPIENT, "Recipient mismatch");
        assertEq(depositAmount, deposit, "Deposit mismatch");
        assertEq(ratePerSecond, 1, "ratePerSecond mismatch");
    }
}