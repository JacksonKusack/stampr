# ---- roxygen documentation ----
#
#' @title stamp.distance
#'
#' @description
#'  The function \code{stamp.distance} can be used to compute various measures of distance 
#'  between polygon events and groups. In turn, distance measurements can be used to estimate the velocity
#'  of polygon movement.
#'
#' @details
#'  \code{stamp.distance} computes distance between polygon sets based on either centroid or
#'    Hausdorff distance calculations. Centroid distance is simply the distance from the centroid
#'    of all T1 polygons (combined) to each stamp event (\code{group = FALSE}), or to the union of
#'    all T2 polygons within a group (\code{group = TRUE}), in the second case, all events within a group
#'    are given an identical distance value.\cr\cr
#'    The Hausdorff distance calculation uses the discrete version of the Hausdorff distance, as
#'    programmed in the \code{rgeos} function \code{gDistance}. A value of \code{densifyFrac = 1} is used
#'    to increase the precision of this measurement -- see \code{help(gDistance)}. The returned distance
#'    is then the Hausdorff distance of all T1 polygons (combined) to each stamp event (\code{group = FALSE}),
#'    or to the union of all T2 polygons within a group (\code{group = TRUE}), in the second case, all events 
#'    within a group are given an identical distance value.
#'
#' @param stmp a \code{SpatialPolygonsDataFrame} object generated from the \code{stamp} function.
#' @param dist.mode Character determining the emethod by which polygon distances are computed. If \code{"Centroid"}
#'    then the centroid distance is calculated, if \code{"Hausdorff"} then the discrete Hausdorff distance
#'    is calculated; see \code{Details}.
#' @param group logical indicating whether distances should be computed from the T1 polygon to each individual 
#'    stamp event (\code{group = FALSE} -- the default), or whether T2 polygons should combined (through a spatial 
#'    union) in order to compute the measure of distance for each stamp group (\code{group = TRUE})
#'
#' @return
#'  Appropriately named columns (e.g., \code{CENDIST} or \code{HAUSDIST}) in the stamp \code{SpatialPolygonsDataFrame}
#'  object.
#'
#' @references 
#'  Hausdorff Distance: \url{http://en.wikipedia.org/wiki/Hausdorff_distance}
#'     
#' @keywords stamp
#' @seealso stamp stamp.direction stamp.shape gDistance
#' @export
# ---- End of roxygen documentation ----

stamp.distance <- function(stmp, dist.mode="Centroid",group=FALSE){
  
#==============================================================================
# Centroid Distance Function
# If group = FALSE (default) Computes distance between centroid of ALL T1 polys
#                            and each stamp event.
# If group = TRUE Computes distance between centroid of ALL T1 polys and ALL 
#                 T2 polys, and returns the same value for each event. 
#==============================================================================
CentroidDistance <- function(stmp,group=FALSE){
  stmp$CENDIST <- NA
  grps <- unique(stmp$GROUP)
  for (i in grps){
    ind <- which(stmp$GROUP == i)
    if (length(ind) > 1){   #no movement for individual events
      #Assumes that all T1 events in a group form the basis of the centroid..
      t1.base <- stmp[which(stmp$GROUP == i & is.na(stmp$ID1) == FALSE),]
      c1 <- gCentroid(t1.base)   #gCentroid is an "area-weighted" centroid function
      
      #compute centroid distance between group centroids only
      if (group == TRUE){
        t2.base <- stmp[which(stmp$GROUP == i & is.na(stmp$ID2) == FALSE),]
        c2 <- gCentroid(t2.base)
        cenDist <- gDistance(c1,c2)
        stmp$CENDIST[ind] <- cenDist
      } else {
      for (j in ind){
        #Compute Centroid distance to each event
        c2 <- gCentroid(stmp[j,])
        cenDist <- gDistance(c1,c2)
        stmp$CENDIST[j] <- cenDist
        }
      }
    }
  }
  return(stmp)
}
#--------- End of Centroid Distance Function ----------------------------------

#==============================================================================
# Hausdorff Distance (Discrete) Function
# If group = FALSE (default) Computes Hausdorff distance between union of ALL 
#                            T1 polys and each stamp event.
# If group = TRUE Computes Hasdorff distance between union of ALL T1 polys and
#                 union of ALL T2 polys, and returns the same value for each 
#                 event. 
#==============================================================================
HausdorffDistance <- function(stmp,group=FALSE){  
  stmp$HAUSDIST <- NA
  grps <- unique(stmp$GROUP)
  for (i in grps){
    ind <- which(stmp$GROUP == i)
    if (length(ind) > 1){
      t1.base <- stmp[which(stmp$GROUP == i & is.na(stmp$ID1) == FALSE),]
      c1 <- gUnaryUnion(t1.base) 
    
      #compute Hausdorff distance using gDistance function...
      if (group == TRUE){
        t2.base <- stmp[which(stmp$GROUP == i & is.na(stmp$ID2) == FALSE),]
        c2 <- gUnaryUnion(t2.base)
        hauDist <- gDistance(c1,c2, hausdorff=TRUE, densifyFrac=0.1)
        stmp$HAUSDIST[ind] <- hauDist
      } else {
      for (j in ind){
        #Compute Hausdorff distance to each event
        c2 <- gUnaryUnion(stmp[j,])
        hauDist <- gDistance(c1,c2, hausdorff=TRUE, densifyFrac=0.1)
        stmp$HAUSDIST[j] <- hauDist
        }
      }
    }
  }
  return(stmp)
}
#---------- End of Hausdorff Distance Function --------------------------------    


#Compute function results based on input method.
stmp <- switch(dist.mode,
               Centroid = CentroidDistance(stmp,group),
               Hausdorff = HausdorffDistance(stmp,group),
               stop(paste("The direction method is does not exist: ",dist.mode)))
return(stmp)

} #End of function