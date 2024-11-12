# Stat628 Module3 Group2
## Predicting Flight Status

### First Step: Data Cleaning
For the data-cleaning process, you need to use the code we provide first to filter the outliers from the flight data set and then you will need to merge the operating airline
companies with the flight ID. After that, you will use the indexed script we provide to index all the data from 18-1 to 24-1. The last step will be to merge the flight data with the
weather data we collect from the website.

### Second Step: Data visualized
From the script of Task1, you will have some data visualization code, which will give you some insight into how to avoid flight that has a high cancellation rate and date
that might be optimal to take a flight.

### Third Step: Prediction of cancellation
In this step, we used logistic regression to fit a model to predict if the flight will be canceled or not. In the script of Task 1, we output the AUC curve to interpret the 
power of our model. The accuracy is about 0.73 and the AUC is about 0.76 after balancing the input data.

### Fourth Step: Prediction of Arrived early or on time
In this step, we used the random forest to predict if the flight would arrive early or on time. In the script of Task 2, you can see the tips about which airline companies will have
a relatively high early arrival rate and how many times they might arrive early. Also, we plot the importance scores of the random forest, which will interpret which features
are the most important in the random forest model. It will be interesting to compare feature importance between logistic regression and random forest.

### Last Step: Predict the flight arrival time or Cancellation
In this step, we used three ml algorithms (RF, XGBoost, LightGBM) to predict level of delay. The independent variables continued from those used in Task 1, while the dependent variable followed from Task 2. 
Due to class imbalance, we applied a full resampling technique to balance the dataset, adjusting the sample size of each class to match the size of the smallest class. 
Evaluation metrics of Accuracy and micro F1-score were utilized to assess model performance. All samples were divided into disjoint training and test samples in a ratio of 4:1.
