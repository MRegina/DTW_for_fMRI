# -*- coding: utf-8 -*-
"""
Created on Sun May  6 21:01:23 2018

@author: MRegina

Easy-to-use Python code for DTW distance based connectivity calculations for fMRI data, enabling parallel processing of different
fMRI measurements with the multiprocessing toolbox. (a lot slower than the c++ version, but can be used in ROI based analysis)

"""
import numpy as np
import time
from multiprocessing import Pool


def dtw(s, t, w, scale_with_timeseries_length=False):
    """Returns DTW distance values between two time-series with Euclidean distance.
            Parameters
            ----------
            s: list or numpy array containing the values of the first time-series
            t: list or numpy array containing the values of the second time-series
            w: positive integer, warping window size
            scale_with_timeseries_length: bool, whether or not divide DTW distance by the time-series length (default is False)
            Returns
            -------
            dtw_distance : float, the DTW distance between time-series s and t
            """
    # allocate DTW matrix and fill it with large values
    Dwt = np.ones([len(s) + 1, len(t) + 1]) * float("inf")

    # set warping window size (if the length difference between the two time series is large, which is NOT the fMRI use-case)
    w = max(w, abs(len(s) - len(t)))

    Dwt[0, 0] = 0

    # precalculate the squared difference between each time-series element pair
    cost = np.square(np.transpose(np.tile(s, [len(t), 1])) - np.tile(t, [len(s), 1]))

    # fill the DTW matrix
    for i in range(len(s)):
        for j in range(max(0, i - w), min(len(t), i + w)):
            Dwt[i + 1, j + 1] = cost[i, j] + np.min([Dwt[i, j + 1], Dwt[i + 1, j], Dwt[i, j]])

    # to obtain Euclidean distance take the square root of the last element of the matrix
    dtw_distance = np.sqrt(Dwt[-1, -1])

    if scale_with_timeseries_length:
        dtw_distance / min(len(s), len(t))

    return dtw_distance


def dtw_connectome(time_series, w):
    """Returns the lower triangle of the connectivity matrix between regions.
                Parameters
                ----------
                time_series: 2D numpy array or array-like object (n x m), containing time-series of brain regions
                            (each column contains a time-series of a ROI): n is the length of the time-series and m is the number of ROIs
                w: positive integer, warping window size
                Returns
                -------
                dtw_distances : 1D numpy array, the pairwise DTW distance values between every pair of time-series in time-series (lower triangle of the connectivity matrix)
                """

    start_time = time.time()

    # reset NaNs and infs
    time_series = np.nan_to_num(time_series)

    # create the list of pairwise DTW distance values
    dtw_distances = []

    # calculate the lower triangle of the connectivity matrix
    for i in range(1, time_series.shape[1]):
        for j in range(0, i):
            dtw_distances.append(dtw(time_series[:, i], time_series[:, j], w))

    print("--- %s seconds ---" % (time.time() - start_time))

    # return list of DTW distances as a numpy array
    return np.array(dtw_distances)


def dtw_connectomes_from_thread(time_series_list, w=50):
    """Returns the lower triangles of the connectivity matrices for a list of measurements.
                    Parameters
                    ----------
                    time_series_list: list of 2D numpy arrays or array-like objects s x(n x m), s is the number of measurements (or subjects),
                                      and each element of the s long list contains the time-series of brain regions(each column contains a
                                      time-series of a ROI): n is the length of the time-series and m is the number of ROIs
                    w: positive integer, warping window size, default is 50 if the TR is around 2 s
                    Returns
                    -------
                    dtw_distances_list : list of 1D numpy arrays, each element of the s long list contains the pairwise DTW distance values between
                                         every pair of time-series in time-series (lower triangle of the connectivity matrix)
                    """
    print("connectome processing starts")

    # create list of DTW distance connectomes
    dtw_distances_list = []

    # iterate over measurements in the list of measurements
    for time_series in time_series_list:
        dtw_distances_list.append(dtw_connectome(time_series, w))

    return dtw_distances_list


def calculate_dtw_connectomes(num_threads, time_series_list):
    """Returns the lower triangles of the connectivity matrices for a list of measurements, with parallel processing in threads.
                        Parameters
                        ----------
                        num_threads: positive integer, the number of threads for parallel processing of measurements
                        time_series_list: list of 2D numpy arrays or array-like objects s x(n x m), s is the number of measurements (or subjects),
                                          and each element of the s long list contains the time-series of brain regions(each column contains a
                                          time-series of a ROI): n is the length of the time-series and m is the number of ROIs
                        Returns
                        -------
                        dtw_distances_array : 2D numpy array (s x (m x(m-1)/2) ), each row of the array contains the pairwise DTW distance values between
                                             every pair of time-series in time-series (lower triangle of the connectivity matrix)
                        """

    # check if the number of measurements is high enough for parallel processing
    if len(time_series_list) < num_threads:
        raise ValueError('Number of threads (%d) must be less than the number of subjects/measurements (%d)' % (
        num_threads, len(time_series_list)))

    # calculate the index boundaries: which time_series_list elements should be processed by which threads
    boundaries = (np.ceil(len(time_series_list) / num_threads) * np.arange(0, num_threads + 1)).astype(np.int)
    boundaries[-1] = min(boundaries[-1], len(time_series_list))

    # create list of lists of time-series, so every thread can operate on its own list of time-series
    time_series_list_for_pool = []
    for i in range(num_threads):
        time_series_list_for_pool.append(time_series_list[boundaries[i]:boundaries[i + 1]])

    # create pool for parallel processing
    pool = Pool(processes=num_threads)

    # run DTW distance calculations parallel for the time-series lists of each thread
    # (NOTE: dtw_connectomes_from_thread uses the default warping window size!)
    dtw_distances = (pool.map(dtw_connectomes_from_thread, time_series_list_for_pool))

    # create one continous list from the list of lists returned by the threads
    dtw_distances_list = [item for sublist in dtw_distances for item in sublist]

    # create a numpy array of size number of measurements x length of lower triangle of the connectivity matrix
    dtw_distances_array = np.zeros([len(dtw_distances_list), len(dtw_distances_list[0])])
    for i in range(len(dtw_distances_list)):
        dtw_distances_array[i, :] = dtw_distances_list[i]

    return dtw_distances_array
