#ifndef READIN_h
#define READIN_H

#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <string>

using namespace std;

//function parseCSV segments string s to a string vector sVec, based on the positions of a delimeter character. The default delimeter is '\t'
void parseCSV(string& s, vector<string>& sVec, char delimeter = '\t')
{
	stringstream stringStream(s);
	string element;

	while (getline(stringStream, element, delimeter))
	{
		sVec.push_back(element);
	}

};

// function readInNames parses the string containing subject name, input path of time-series data, dataset ID and run ID
void readInNames(string line, string &subname, string& inputPath, int& dataset, int& run)
{
	vector<string> readLine;
	parseCSV(line, readLine);

	subname = readLine[0];
	cout << subname << "\n";

	inputPath = readLine[1];
	cout << inputPath << "\n";

	dataset = stod(readLine[2]);
	cout << dataset << "\t";

	run = stod(readLine[3]);
	cout << run << "\n";
}


//function readIn parses text file containing the time-series data to vector<vector< INT64 > >: each column contains a time-series 
void readIn(string input, vector<vector< INT64 > > &data)
{
	ifstream inputStream;
	inputStream.open(input);

	string line;		//define string to read in data

	getline(inputStream, line);

	vector<string> firstLine;
	parseCSV(line, firstLine);	//parse string line

	data.reserve(1000);	//reserve the number of time-series we have

	// create datastructure for the time series vectors: we count how many time-series we have from the first line
	for (vector<string>::iterator it = firstLine.begin(); it != firstLine.end(); it++)
	{
		INT64 d = (stod(*it)) * 10000;	//stod creates double from string, we convert to int64: max 4 decimals

		vector <INT64> intVec;
		intVec.reserve(300);	//reserve the number of time-points we have
		intVec.push_back(d);

		data.push_back(intVec);
	}

	// fill the whole datastructure with the remaining lines
	while (getline(inputStream, line))
	{
		vector<string> sSeries;		// declare string vector to parse data into it
		sSeries.reserve(1000);	//reserve the number of time-series we have

		parseCSV(line, sSeries);	//parse string line

		// fill datastructure with the time series data
		vector<vector< INT64 > >::iterator beg = data.begin();
		for (vector<string>::iterator it = sSeries.begin(); it != sSeries.end(); it++)
		{
			INT64 d = ((stod(*it)) * 10000);	//stod creates double from string, we convert to int64: max 4 decimals
			(*beg).push_back(d);	
			beg++;
		}
	}

};
#endif