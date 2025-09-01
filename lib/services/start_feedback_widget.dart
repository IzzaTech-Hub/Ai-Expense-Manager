import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:vidcraft_ai/app/utils/app_sizes.dart';
// import 'package:google_fonts/google_fonts.dart';


class StarFeedbackWidget extends StatefulWidget {
  final double size;
  final BuildContext mainContext;
  final bool isShowText;
  final IconData icon;

  const StarFeedbackWidget({
    Key? key,
    required this.size,
    required this.mainContext,
    this.isShowText = false,
    required this.icon,
  }) : super(key: key);

  @override
  State<StarFeedbackWidget> createState() => _StarFeedbackWidgetState();
}

class _StarFeedbackWidgetState extends State<StarFeedbackWidget> {
  bool isStarred = false; // Track if feedback is given
  String? selectedFeedback; // Selected feedback option
  String? feedbackType = "Negative"; // Default feedback type
  TextEditingController customFeedbackController = TextEditingController();

  final Map<String, List<String>> feedbackOptions = {
    "Positive": [
      "Helpful response",
      "Clear and easy to understand",
      "Accurate information",
      "Good financial advice",
      "Well explained",
      "Other",
    ],
    "Negative": [
      "Confusing or unclear",
      "Inaccurate information",
      "Not helpful",
      "Inappropriate content",
      "Technical issue",
      "Other",
    ],
  };
  void showFeedbackDialog(BuildContext mainContext) {
    if (!mounted) return; // Check if widget is still mounted
    
    // Reset state for new dialog
    selectedFeedback = null;
    feedbackType = "Positive"; // Default to positive
    customFeedbackController.clear();
    
    try {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, dialogSetState) {
              return AlertDialog(
                title: const Text("Rate AI Response"),
                content: SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Positive/Negative Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<String>(
                              value: "Positive",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                dialogSetState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Positive"),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: "Negative",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                dialogSetState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Negative"),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Feedback Options
                        ...feedbackOptions[feedbackType]!.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: selectedFeedback,
                            onChanged: (value) {
                              dialogSetState(() {
                                selectedFeedback = value;
                                if (value != "Other") {
                                  customFeedbackController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),

                        // Show TextField if "Other" is selected
                        if (selectedFeedback == "Other")
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextField(
                              controller: customFeedbackController,
                              decoration: const InputDecoration(
                                labelText: "Your feedback",
                                border: OutlineInputBorder(),
                                hintText: "Enter your feedback here...",
                              ),
                              maxLines: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      String finalFeedback = selectedFeedback == "Other"
                          ? customFeedbackController.text
                          : selectedFeedback ?? "";

                      if (finalFeedback.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please provide feedback."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Update the widget state
                      setState(() {
                        isStarred = true;
                      });

                      try {
                        await FirebaseFirestore.instance
                            .collection('ai_feedback')
                            .add({
                              'reason': finalFeedback,
                              'type': feedbackType,
                              'reportedAt': DateTime.now(),
                              'source': 'ai_assistant',
                            });
                        
                        // Show success dialog
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Thank You!"),
                                content: const Text(
                                  "Your feedback helps us improve the AI assistant.",
                                ),
                              );
                            },
                          );

                          // Close dialog after 1 second
                          Future.delayed(const Duration(seconds: 1), () {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close Thank You dialog
                              Navigator.of(context).pop(); // Close original dialog
                            }
                          });
                        }
                      } catch (e) {
                        print('Error saving feedback: $e');
                        // Show error message but still close dialog
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving feedback: $e'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.of(context).pop(); // Close dialog
                        }
                      }
                    },
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print("Error showing feedback dialog: $e");
      Navigator.of(context).pop(); // Close original feedback dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    double size = widget.size;
    IconData icon = widget.icon;
    final buildContext = widget.mainContext;
    
    // Check if the main context is still valid
    if (!buildContext.mounted) {
      return const SizedBox.shrink(); // Return empty widget if context is invalid
    }
    
    return GestureDetector(
      onTap: () {
        showFeedbackDialog(buildContext);
      },
      child: Row(
        children: [
          widget.isShowText
              ? Text(
                  "Feedback",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  // GoogleFonts.nunitoSans(
                  // ),
                )
              : Container(),
          Container(
            // width: SizeConfig.blockSizeHorizontal * size,
            // height: SizeConfig.blockSizeHorizontal * size,
            // padding: EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(4),
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(30),
             ),
                         child: Center(
               child: Icon(icon, color: Colors.grey[600], size: size),
             ),
          ),
        ],
      ),
    );
  }
}
