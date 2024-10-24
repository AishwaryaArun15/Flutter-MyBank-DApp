import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dapp/models/transaction.model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardInitialFetchEvent>(dashboardInitialFetchEvent);
    on<DashboardDepositEvent>(dashboardDepositEvent);
    on<DashboardWithdrawEvent>(dashboardWithdrawEvent);
  }

  List<TransactionModel> transactions = [];
  Web3Client? _web3client;
  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  late EthPrivateKey _creds;
  int balance = 0;

  //contract functions
  late DeployedContract _deployedContract;
  late ContractFunction _deposit;
  late ContractFunction _withdraw;
  late ContractFunction _getBalance;
  late ContractFunction _getAllTransactions;

  Future<void> dashboardInitialFetchEvent(
      DashboardInitialFetchEvent event, Emitter<dynamic> emit) async {
    emit(DashboardLoadingState());
    try {
      const String rpcUrl = "http://10.0.2.2:7545";
      const String socketUrl = "ws://10.0.2.2:7545";
      const String privateKey =
          "0x0427a25f404285550dfe96e7830547d0c48503765a2ee0da78b4b10e86bbc271";

      _web3client = Web3Client(rpcUrl, http.Client(), socketConnector: () {
        return IOWebSocketChannel.connect(socketUrl).cast<String>();
      });

      //get abi file and credentials
      String abiFile = await rootBundle
          .loadString('build/contracts/ExpenseManagerContract.json');
      var jsonDecoded = jsonDecode(abiFile);
      _abiCode = ContractAbi.fromJson(
          jsonEncode(jsonDecoded['abi']), 'ExpenseManagerContract');
      _contractAddress =
          EthereumAddress.fromHex("0xb75a36a59d84f3994C23eCdDc8A0aefb4e6b93c7");
      _creds = EthPrivateKey.fromHex(privateKey);

      //get deployed contract
      _deployedContract = DeployedContract(_abiCode, _contractAddress);
      _deposit = _deployedContract.function("deposit");
      _withdraw = _deployedContract.function("withdraw");
      _getBalance = _deployedContract.function("getBalance");
      _getAllTransactions = _deployedContract.function("getAllTrasactions");

      final transactionData = await _web3client!.call(
          sender: EthereumAddress.fromHex(
              "0xA7D34048d0C75F5fcdFEDc11F0e84c43A550297e"),
          contract: _deployedContract,
          function: _getAllTransactions,
          params: []);
      final balanceData = await _web3client!
          .call(contract: _deployedContract, function: _getBalance, params: [
        EthereumAddress.fromHex("0xA7D34048d0C75F5fcdFEDc11F0e84c43A550297e")
      ]);
      List<TransactionModel> trans = [];

      for (int i = 0; i < transactionData[0].length; i++) {
        TransactionModel transactionModel = TransactionModel(
            transactionData[0][i].toString(),
            transactionData[1][i].toInt(),
            transactionData[2][i],
            DateTime.fromMicrosecondsSinceEpoch(transactionData[3][i].toInt()));
        trans.add(transactionModel);
      }
      transactions = trans;
      int bal = balanceData[0].toInt();
      balance = bal;

      emit(DashboardSuccessState(transactions: transactions, balance: balance));
    } catch (e) {
      emit(DashboardErrorState());
      print(e.toString());
    }
  }

  FutureOr<void> dashboardDepositEvent(
      DashboardDepositEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
        contract: _deployedContract,
        function: _deposit,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason
        ],
        value: EtherAmount.inWei(
          BigInt.from(event.transactionModel.amount),
        ),
      );

      final result = await _web3client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      add(DashboardInitialFetchEvent());
    } catch (e) {
      print(e.toString());
    }
  }

  FutureOr<void> dashboardWithdrawEvent(
      DashboardWithdrawEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
        contract: _deployedContract,
        function: _withdraw,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason
        ],
      );

      final result = await _web3client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      add(DashboardInitialFetchEvent());
    } catch (e) {
      print(e.toString());
    }
  }
}
