import 'package:dapp/dashboard/bloc/dashboard_bloc.dart';
import 'package:dapp/models/transaction.model.dart';
import 'package:flutter/material.dart';

class WithdrawPage extends StatefulWidget {
  final DashboardBloc dashboardBloc;
  const WithdrawPage({super.key, required this.dashboardBloc});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Withdraw Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 8,
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: "Enter the Amount",
              ),
            ),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: "Enter the Reason",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.dashboardBloc.add(
                  DashboardWithdrawEvent(
                    transactionModel: TransactionModel(
                        addressController.text,
                        int.parse(amountController.text),
                        reasonController.text,
                        DateTime.now()),
                  ),
                );
                Navigator.pop(context);
              },
              child: Text("- Withdraw"),
            )
          ],
        ),
      ),
    );
    ;
  }
}
