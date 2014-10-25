# training function
# 
# -----
# input:
#       x : feature vector
#       y : desired response
#  is.feat: whether feature selection is required. [default: TRUE] 
#  method : classifier type
# 
#  output:
#   export training results as a file, including train model and model evaluation
# 
#
"train.mwas" <- function(x, y, is.feat = TRUE, 
                         method=c("RF","SVM", "knn", "MLR")[1], ...){
  if (is.feat){
    feat.set <- feature.scores.mwas(x, y, selection_threshold = 0)
    train.set <- x[,feat.set$ix]
  }
  else train.set <- x
  
  best.model <- persist.model.mwas(train.set, y, nfolds=10, classifier=method, ...)
  
  export.mwas(trained.model = best.model, feat.set = feat.set)
  return()
}


# nested cross-validation or Jackknifing
# -- input
#          x : feature vector
#          y : desired labels
#     nfolds : number of folds 
# classifier : type of classifier
#       opts : options passed from keyboards
# -- output
#  best.model : model parameters

"persist.model.mwas" <- function(x, y, nfolds=10, 
                               classifier=c("RF","SVM", "knn", "MLR")[1],...){
  # x - feature set (observation * features)
  # y - desried response
  cv.ind <- sample(dim(x)[1])
  cv.samp.num <- floor(length(cv.ind)/nfolds)
  sampl_ind <- seq(1, dim(x)[1], by=1)
  candidate.model <- list()
  candidate.rocobj <- list()
  
  # nested cross-validation
  for (cv.id in 1:nfolds){
    if(cv.id < nfolds)
      idx <- cv.ind[seq((cv.id-1)*cv.samp.num + 1, cv.id*cv.samp.num, by=1)]
    else
      idx <- cv.ind[seq((cv.id-1)*cv.samp.num + 1, length(cv.ind), by=1)]
    
    train.set <- x[idx,]
    train.labels <- y[idx]
    
    validation.set <- x[!sampl_ind %in% idx,]
    validation.labels <- y[!sampl_ind %in% idx]
    
    candidate.model[[cv.ind]] <- cross.validation(train.set, train.labels, nfolds, classifier, ...)
    candidate.rocobj[[cv.ind]] <- roc.mwas(validation.set, model = candidate.model[cv.ind], response = validation.labels)
  }
  
  ####### ISSUE: train final model on whole data set
  #best.ind <- which.max(candidate.rocobj$auc) #### find the best auc index?
  #best.model <- candidate.model[best.ind]
  best.model <- cross.validation(x, y, nfolds, classifier, ...)
  
  
  ####### ISSUE: Calculate mean and std of error/AUC, MCC, Kappa
  # using candidate.rocobj
  #
  
  
  
  # if (savefile) save(best.model, file = paste(opts$outdir,"/trained.model", collapse='', sep=''))
  # Saving file is integrated into export.mwas.R
  
  return(best.model)
}


# Jackknife 
# 1) parameters estimated from the whole sample data
# 2) each element is, in turn, dropped from the sample 
#    and the parameter of interest is estimated from this smaller sample.
# 3) the difference between the whole sample estimation and the partial estimate 
#    is computed --- called pseudo-values
# 4) The pseudo-values are used in lieu of the original values to estimate the 
#    parameter of interest and their standard deviation is used to estimate the 
#    parameter standard error.
# --------
# -- input
#          x : feature vector
#          y : desired labels
#     nfolds : number of folds 
# classifier : type of classifier
# -- output
#  model estimation : error and standard deviation

"jackknife.mwas" <- function(x, y, nfolds=10, 
                                classifier=c("RF","SVM", "knn", "MLR")[1],...){
  # x - feature set (observation * features)
  # y - desried response
  cv.ind <- sample(dim(x)[1])
  cv.samp.num <- floor(length(cv.ind)/nfolds)
  sampl_ind <- seq(1, dim(x)[1], by=1)
  candidate.model <- list()
  candidate.rocobj <- list()
  
  # jackknife function here
  #
  
  return(model.estimate)
}



# cross-validation 
# -- input
#          x : feature vector
#          y : desired labels
#     nfolds : number of folds 
# classifier : type of classifier
# -- output
#  best.model : model parameters

"cross.validation.mwas" <- function(x, y, nfolds=10, classifier = c("RF","SVM", "knn", "MLR")[1], ...){
  
  if(classifier == "RF")
    best.model <- tune.randomForest(x, y, tunecontrol = tune.control(random=TRUE, sampling="cross", cross = nfolds, fix = 2/3))
    # $best.performance     the error rate for the best model
    # $train.ind            list of index vectors used for splits into training and validation sets
    # $performances         error and dispersion; a data frame with all parametere combinations along with the corresponding performance results
    # $best.model           best model parameter list
    #   -- $predicted       the predicted values of the input data based on out-of-bag samples
    #   -- $err.rate        vector error rates of the prediction on the input data, the i-th element being the (OOB) error rate for all trees up to the i-th.
    #   -- $confusion       confusion matrix for the training set
    #   -- $votes           a matrix with one row for each input data point and one column for each class, giving the fraction or number of (OOB) ‘votes’ from the random forest
    #   -- $oob.times       number of times cases are ‘out-of-bag’ 
    #   -- $classes         class (category) names
    #   -- $importance      <check ?randomForest>
    #   -- $importanceSd    the “standard errors” of the permutation-based importance measure
    #   -- $localImportance <check ?randomForest>
    #   -- $ntree           number of trees grown
    #   -- $mtry            number of predictors sampled for spliting at each node
    #   -- $forest          a list that contains the entire forest
    #   -- $y               the desired labels for the training set
    #   -- $inbag, $test
  
  else if(classifier == "SVM")
    best.model <- tune.svm(x, y, tunecontrol = tune.control(random=TRUE, sampling="cross", cross = nfolds))
    # $best.model         the model trained on the complete training data using the best parameter combination.
    # $best.parameters    a 1 x k data frame, k number of parameters
    # $best.performance   best achieved performance
    # $performances       a data frame with all parametere combinations along with the corresponding performance results
    # $train.ind          list of index vectors used for splits into training and validation sets
      
  else if(classifier == "MLR") 
    best.model <- cv.glmnet(x, y, nfolds = nfolds)
    # $glmnet.fit   a fitted glmnet object for the full data
    # $cvm          mean cross-validation error    
    # $cvsd         estimate of standard error of cvm
    # $cvup         upper curve = cvm+cvsd
    # $cvlo         lower curve = cvm-cvsd
    # $nzero        number of non-zero coefficients at each lambda
    # $name         type of measure (for plotting purposes)
    # $lambda.min   value of labda that gives minimum cvm
    # $lambda.lse   largest value of lambda such that error is within 1 standard error of the minimum
    # $fit.preval, $foldid
  
  else if (classifier == "knn")
    best.model <- tune.knn(x, y, k =c(1,3,5,7,9,11,13,15,17,19,21,23,25), l=NULL, sampling="cross", cross = nfolds, prob = TRUE) 
    # $best.parameters$k          best k
    # $best.performance           classification error using best k
    # $performances$k             all candidate k's that used in cross-validation
    # $performances$error         errors for all candidates
    # $performances$dispersion    dispersions for all candidates
    # $best.model                 best model list 
  
  return(best.model)
}