#pragma once
// Clean-room replacement for the SHOUTcast DNAS (sc_serv3) internal helper of
// the same name. SHOUTcast is distributed as licensed binaries only, so the
// original header cannot be redistributed or referenced; this provides just
// the two std::string helpers the SHOUTcast DSP source path uses.
#include <string>

namespace stringUtil
{
	// Returns the input reduced to its alphanumeric characters, so an empty
	// result identifies titles made up only of whitespace and punctuation.
	inline std::string stripAlphaDigit(const std::string &input)
	{
		std::string output;
		output.reserve(input.size());
		for (char c : input)
		{
			if (isalnum((unsigned char)c))
				output.push_back(c);
		}
		return output;
	}

	inline std::string toLower(const std::string &input)
	{
		std::string output(input);
		for (char &c : output)
		{
			c = (char)tolower((unsigned char)c);
		}
		return output;
	}
}
