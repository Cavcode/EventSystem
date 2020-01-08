/*
    ScriptName: es_inc_nss.nss
    Created by: Daz

    Description: Event System NSS Utility Include
*/

string nssVoidMain(string sContents);
string nssStartingConditional(string sContents);
string nssInclude(string sIncludeFile);
string nssIfStatement(string sFunction, string sComparison = "", string sValue = "");
string nssElseIfStatement(string sFunction, string sComparison = "", string sValue = "");
string nssWhile(string sFunction, string sComparison = "", string sValue = "");
string nssBrackets(string sContents);
string nssEscapeDoubleQuotes(string sString);
string nssSwitch(string sVariable, string sCases);
string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE);
string nssObject(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssString(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssInt(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssFloat(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssVector(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssLocation(string sVarName, string sFunction = "", int bIncludeType = TRUE);
string nssFunction(string sFunction, string sArguments = "", int bAddSemicolon = TRUE);

string nssVoidMain(string sContents)
{
    return "void main() { " + sContents + " }";
}

string nssStartingConditional(string sContents)
{
    return "int StartingConditional() { return " + sContents + " }";
}

string nssInclude(string sIncludeFile)
{
    return sIncludeFile == "" ? sIncludeFile : "#" + "include \"" + sIncludeFile + "\" ";
}

string nssIfStatement(string sFunction, string sComparison, string sValue)
{
    return "if (" + sFunction + " " + sComparison + " " + sValue + ") ";
}

string nssElseIfStatement(string sFunction, string sComparison, string sValue)
{
    return "else if (" + sFunction + " " + sComparison + " " + sValue + ") ";
}

string nssWhile(string sFunction, string sComparison, string sValue)
{
    return "while (" + sFunction + " " + sComparison + " " + sValue + ") ";
}

string nssBrackets(string sContents)
{
    return "{ " + sContents + " } ";
}

string nssEscapeDoubleQuotes(string sString)
{
    return "\"" + sString + "\"";
}

string nssSwitch(string sVariable, string sCases)
{
    return "switch (" + sVariable + ") { " + sCases + " }";
}

string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE)
{
    return "case " + IntToString(nCase) + ": { " + sContents + (bBreak ? " break;" : "") + " } ";
}

string nssSemicolon(string sString)
{
    return (GetStringRight(sString, 1) == ";" || GetStringRight(sString, 2) == "; ") ? sString + " " : sString + "; ";
}

string nssVariable(string sType, string sVarName, string sFunction)
{
    return sType + " " + sVarName + (sFunction == "" ? "; " : " = " + nssSemicolon(sFunction));
}

string nssObject(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "object" : "", sVarName, sFunction);
}

string nssString(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "string" : "", sVarName, sFunction);
}

string nssInt(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "int" : "", sVarName, sFunction);
}

string nssFloat(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "float" : "", sVarName, sFunction);
}

string nssVector(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "vector" : "", sVarName, sFunction);
}

string nssLocation(string sVarName, string sFunction = "", int bIncludeType = TRUE)
{
    return nssVariable(bIncludeType ? "location" : "", sVarName, sFunction);
}

string nssFunction(string sFunction, string sArguments, int bAddSemicolon = TRUE)
{
    return sFunction + "(" + sArguments + (bAddSemicolon ? ");" : ")") + " ";
}

