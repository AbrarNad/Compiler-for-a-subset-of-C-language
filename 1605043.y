%{
#include<iostream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1605043_SymbolTable.h"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE *fp;
FILE *logout;
//FILE *errorout;
//FILE *codeOut;
FILE *optout;

vector<SymbolInfo*> dec_list;
vector<string> parList;
vector<string> parType;
vector<SymbolInfo*> func_list;
vector<string> arg_list;
vector<string> arg_name;

vector<string> varList;
vector<string> arrList;

string currentFunc;

int line_count =1;
int errCount = 0;

symbolTable *table = new symbolTable(30);

int labelCount=0;
int tempCount=0;

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

void yyerror(const char *s)
{
	fprintf(logout ,"Syntax Error at line no: %d\n", line_count);
	errCount++;
	//fprintf(errorout ,"Syntax Error at line no: %d\n", line_count);
}

void optimize(int n);
vector<string> stringSplit(string s, char delim);
bool compare(string s1, string s2, int n);


%}

//%define api.value.type{SymbolInfo*}
%token IF ELSE FOR WHILE DO BREAK INT FLOAT DOUBLE CHAR RETURN VOID MAIN PRINTLN ADDOP MULOP CONST_INT CONST_FLOAT ID COMMA ASSIGNOP RELOP LOGICOP NOT SEMICOLON LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		$$ = new SymbolInfo();
		fprintf(logout ,"At line no: %d start : program\n", line_count);


		//fprintf(logout, "\n");
		$$->setID($1->id);
		table->printAll(logout);

		fprintf(logout ,"\n\n\nTotal Lines: %d\n", line_count);
		fprintf(logout ,"\nTotal Errors: %d\n", errCount);
		fprintf(logout ,"\n\n\nTotal Errors: %d\n", errCount);

		$$->code +=".model small\n.stack 100h\n\n\n.data\n\n";
		for(int i= 0; i<tempCount; i++)
		{
			$$->code += "t"+ to_string(i) + " dw 0\n";
		}

		for(int i= 0; i<varList.size(); i++)
		{
			$$->code += varList[i] + " dw ?\n";
		}

		for(int i= 0; i<arrList.size(); i++)
		{
			$$->code += arrList[i] + " dw dup(?)\n";
		}

		$$->code += ".code\n\n" + $1->code + "\n";
		$$->code += "printProc proc\n";
		$$->code += "mov ah, 2\nint 21h\nprintProc endp\nend main";

		ofstream fout;
		fout.open("code.asm");
		fout << $$->code;	

		optimize(2);
		//fprintf(logout, "%s \n",$$->code.c_str());			
	}
	;

program : program unit
	{	
		$$ = new SymbolInfo($1);
		$$->code += $2->code;
		//printf(logout ,"At line no: %d program : program unit\n", line_count);
		//fprintf(logout, "%s \n%s\n\n\n",$1->id.c_str(),$2->id.c_str());
		$$->setID($1->id +" \n"+$2->id);

		//fprintf(logout, "%s \n",$$->code.c_str());	
	}
	| unit
	{
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d program : unit\n", line_count);
		//fprintf(logout, "%s\n\n\n",$1->id.c_str());
		$$->setID($1->id);

		//fprintf(logout, "%s \n",$$->code.c_str());	
	}
	;
	
unit : var_declaration
	 {
		$$ = new SymbolInfo();
		//fprintf(logout ,"At line no: %d unit : var_declaration\n", line_count);
		//fprintf(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);
	 }
     | func_declaration
	 {
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d unit : func_declaration\n", line_count);
		//fprintf(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);

		//fprintf(logout, "%s\n",$$->code.c_str());
	 }
     | func_definition
	 {
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d unit : func_definition\n", line_count);
		//fprintf(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);
		
		//fprintf(logout, "%s\n",$$->code.c_str());
	 }
	 | error SEMICOLON	{	fprintf(logout ,"Error recovery at line no: %d\n", line_count);}
	 | error RCURL	{	fprintf(logout ,"Error recovery at line no: %d\n", line_count);}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			parType.clear();
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n", line_count);
			//fprintf(logout, "%s %s( %s ); \n",$1->id.c_str(),$2->id.c_str(),$4->id.c_str());
			$$->setID($1->id+" "+$2->id+"("+$4->id+")"+";");

			if(table->searchCurrent($2->id) == NULL)
			{
				SymbolInfo *tmp;
				table->insertTable($2->id,"ID","function");
				tmp = table->searchCurrent($2->id);
				tmp->setDeclared();
				tmp->setdType($1->id);
				tmp->setFunc();
				for(int i=0; i<dec_list.size(); i++)
				{
					parType.push_back(dec_list[i]->dType);
					//parList.push_back(dec_list[i]->id+table.getCurrentScope());----
				}
				
				tmp->setParaType(parType);
				//tmp->setParaList(parList);----
				parType.clear();
			}else
			{
				errCount++;
				//fprintf(errorout ,"Error at line no: %d Multiple declaration of %s\n", line_count,$2->id.c_str());		
			}
			dec_list.clear();

		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d func_declaration : type_specifier ID LPAREN  RPAREN SEMICOLON\n", line_count);
			//fprintf(logout, "%s %s( ); \n",$1->id.c_str(),$2->id.c_str());
			$$->setID($1->id+" "+$2->id+"()"+";");

			if(table->searchCurrent($2->id) == NULL)
			{
				SymbolInfo *tmp;
				table->insertTable($2->id,"ID","function");
				tmp = table->searchCurrent($2->id);
				tmp->setDeclared();
				tmp->setdType($1->id);
				tmp->setFunc();
			}else
			{
				errCount++;
				//fprintf(errorout ,"Error at line no: %d Multiple declaration of %s\n", line_count,$2->id.c_str());		
			}
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN
		{
			currentFunc = $2->id;
			vector<string> pushlist;
			for(int i=0; i<parType.size();i++)
			{
				func_list.push_back(new SymbolInfo(parList[i], parType[i],""));
				//pushlist.push_back(dec_list[i]->id+table.getCurrentScope());---
			}
		} compound_statement
		{
			//cout<<"current scope: "<<table->getCurrentScope()<<endl;
			parList.clear();
			parType.clear();
			$$ = new SymbolInfo();
			$$->code+= $2->id + " proc\n\n";
			//fprintf(logout ,"At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n", line_count);
			//fprintf(logout, "%s %s( %s ) \n%s\n",$1->id.c_str(),$2->id.c_str(),$4->id.c_str(),$7->id.c_str());
			$$->setID($1->id+" "+$2->id+"("+$4->id+")\n"+$7->id);

			SymbolInfo *tmp = table->searchCurrent($2->id);
			//if(tmp==NULL)
			//{
				if($2->id != "main")
				{
					$$->code += "push ax \npush bx \npush cx \npush dx \n";
					table->insertTable($2->id,"ID","function");
					tmp = table->searchCurrent($2->id);
					tmp->setDeclared();
					tmp->setDefined();
					tmp->setdType($1->id);
					tmp->setFunc();
					
					for(int i=0; i<func_list.size(); i++)
					{
						parType.push_back(func_list[i]->dType);

						$$->code+= "push "+func_list[i]->id + to_string(table->getCurrentScope()) +"\n";
					}
					for(int i=0; i<dec_list.size(); i++)
					{
						$$->code+= "push "+dec_list[i]->id + to_string(table->getCurrentScope()) +"\n";
					}
					for(int i=0; i<func_list.size(); i++)
					{
						parList.push_back(func_list[i]->id + to_string(table->getCurrentScope()));
					}

					$$->code += "\n\n";
					
				
					tmp->setParaType(parType);
					tmp->setParaList(parList);
					parType.clear();
					parList.clear();
				}

				$$->code += $7->code;
		        $$->code+="end_of_"+$2->id+": \n\n";

				if($2->id != "main")
				{
					for(int i = func_list.size()-1; i>=0; i--)
					{
						$$->code += "pop "+func_list[i]->id+ to_string(table->getCurrentScope())+"\n";
					}
					for(int i = dec_list.size()-1; i>=0; i--)
					{
						$$->code += "pop "+dec_list[i]->id+ to_string(table->getCurrentScope())+"\n";
					}

					$$->code += "pop dx \npop cx \npop bx \npop ax \nret\n\n";
				}

				$$->code += $2->id+" endp\n\n";

			//}else
			/*{
				if(tmp->isDefined())
				{
					errCount++;
					//fprintf(errorout ,"Error at line no: %d Multiple definitions of %s\n", line_count,$2->id.c_str());	
				}else
				{
					bool hello = false;
					if($1->id == tmp->dType && tmp->para_num == func_list.size())
					{
						if(tmp->para_num == 0)
						{
							hello = true;
						}
						for(int i = 0; i<dec_list.size();i++)
						{
							if(dec_list[i]->dType != tmp->paraType[i])
								hello = true;
						}

						if(!hello)
						{
							for(int i=0; i<dec_list.size(); i++)
							{
								parList.push_back(dec_list[i]->id);

								if(dec_list[i]->id == "")
								{
									errCount++;
									//fprintf(errorout ,"Error at line no: %d Invalid parameter list format\n", line_count);
								}
							}

							tmp->setDefined();
							tmp->setParaList(parList);
							tmp->setFunc();
							parList.clear();
						}else
						{
							errCount++;
							//fprintf(errorout ,"Error at line no: %d Mismatched Function signature of %s in Declaration and Definition\n", line_count,$2->id.c_str());	
						}
					}else
					{
						errCount++;
						//fprintf(errorout ,"Error at line no: %d Mismatched Function signature of %s in Declaration and Definition\n", line_count,$2->id.c_str());		
					}
				}
			}*/

			parType.clear();
			parList.clear();
			func_list.clear();
			dec_list.clear();

			//fprintf(logout, "s\n",$$->code.c_str());
		}
		| type_specifier ID LPAREN RPAREN {currentFunc = $2->id;} compound_statement
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", line_count);
			//fprintf(logout, "%s %s() \n%s\n",$1->id.c_str(),$2->id.c_str(),$5->id.c_str());
			$$->setID($1->id+" "+$2->id+"()\n"+$5->id);

			if($2->id != "main")
			{
				$$->code += "push ax \npush bx \npush cx \npush dx \n";

				for(int i=0; i<dec_list.size();i++)
                {

                     $$->code += "push "+dec_list[i]->id + to_string(table->getCurrentScope())+"\n";

                 }
				 $$->code+="\n\n";
			}

			$$->code += $6->code;
			$$->code += "end_of_"+$2->id + ":\n\n";

			if($2->id != "main")
			{
				for(int i=dec_list.size()-1; i>=0;i--)
                {

                     $$->code += "pop "+dec_list[i]->id + to_string(table->getCurrentScope())+"\n";

                 }
				 $$->code+="\n\n";
			}

			$$->code += $2->id+" endp\n\n";

			//fprintf(logout, "s\n",$$->code.c_str());

			SymbolInfo *tmp = table->searchCurrent($2->id);
			if(tmp==NULL)
			{
				table->insertTable($2->id,"ID","function");
				tmp = table->searchCurrent($2->id);
				tmp->setDeclared();
				tmp->setDefined();
				tmp->setdType($1->id);
				tmp->setFunc();
			}else
			{
				if(tmp->isDefined())
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Multiple definitions of %s\n", line_count,$2->id.c_str());	
				}else
				{
					bool hello = false;
					if($1->id == tmp->dType)
					{
						if(tmp->para_num==0)
						{
							tmp->setDefined();
							tmp->setFunc();
						}else
						{
							errCount++;
							fprintf(logout ,"Error at line no: %d Mismatched Function signature of %s in Declaration and Definition\n", line_count,$2->id.c_str());	
						}
					}else
					{
						errCount++;
						fprintf(logout ,"Error at line no: %d Mismatched Function signature of %s in Declaration and Definition\n", line_count,$2->id.c_str());		
					}
				}
			}
			dec_list.clear();

		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d parameter_list  : parameter_list COMMA type_specifier ID\n", line_count);
			//fprintf(logout, "%s, %s %s\n",$1->id.c_str(),$3->id.c_str(),$4->id.c_str());
			parList.push_back($4->id);
			parType.push_back($3->id);
			//dec_list.push_back(new SymbolInfo($4->id,"ID",$3->id));
			$$->setID($1->id+", "+$3->id+" "+$4->id);
			varList.push_back($4->id+ to_string(table->getCurrentScope()) );
		}
		| parameter_list COMMA type_specifier
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d parameter_list  : parameter_list COMMA type_specifier\n", line_count);
			//fprintf(logout, "%s, %s\n",$1->id.c_str(),$3->id.c_str());
			//dec_list.push_back(new SymbolInfo("","ID",$3->id));
			parType.push_back($3->id);
			$$->setID($1->id+", "+$3->id);
		}
 		| type_specifier ID
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d parameter_list  : type_specifier ID\n", line_count);
			//fprintf(logout, "%s %s\n",$1->id.c_str(),$2->id.c_str());
			parType.push_back($1->id);
			parList.push_back($2->id);
			//dec_list.push_back(new SymbolInfo($2->id,"ID",$1->id));
			$$->setID($1->id+" "+$2->id);
			varList.push_back($2->id+ to_string(table->getCurrentScope()) );
		}
		| type_specifier
		{
			$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d parameter_list  : type_specifier\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			//dec_list.push_back(new SymbolInfo("","ID",$1->id));
			parList.push_back("");
			parType.push_back($1->id);
			$$->setID($1->id);
		}
 		;

 		
compound_statement : LCURL 
					{
						table->newScope(logout);
						for(int i=0; i<dec_list.size(); i++)
						{
							if(table->searchCurrent(dec_list[i]->id)==NULL)
							{
									table->insertTable(dec_list[i]->id,dec_list[i]->type,dec_list[i]->dType);
							}
							else
							{
								errCount++;
								fprintf(logout ,"Error at line no: %d Multiple declaration of %s in parameters\n", line_count,dec_list[i]->id.c_str());
							}
							
							/*if(dec_list[i]->isArr)
							{
								arrList.push_back(dec_list[i]->id+ to_string(table->getCurrentScope()));
							}else
							{
								varList.push_back(dec_list[i]->id+ to_string(table->getCurrentScope()));
							}*/
						}
					} 
			statements RCURL
			{
				$$ = new SymbolInfo($3);
				//fprintf(logout ,"At line no: %d compound_statement : LCURL statements RCURL\n", line_count);
				//fprintf(logout, "{\n %s\n}\n",$3->id.c_str());
				$$->setID("{\n"+$3->id+"\n}");
				table->printAll(logout);
				table->exitScope(logout);

				//fprintf(logout, "%s\n",$$->code.c_str());
			}
 		    | LCURL
			{
				table->newScope(logout);
			} 
			 RCURL
			 {
				$$ = new SymbolInfo();
				//fprintf(logout ,"At line no: %d compound_statement : LCURL RCURL\n", line_count);
				//fprintf(logout, "{ }\n");
				$$->setID("{ }");
				//table->printAll(logout);
				table->exitScope(logout);
			 }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
			{
				$$ = new SymbolInfo();

				for(int i=0; i<dec_list.size();i++)
				{
					if(table->searchCurrent(dec_list[i]->id)!=NULL)
					{
						//table->insertTable(dec_list[i]->id,dec_list[i]->type,$1->id);
						errCount++;
						//fprintf(errorout ,"Error at line no: %d Multiple declaration of %s\n", line_count,dec_list[i]->id.c_str());
					}else
					{
						if(dec_list[i]->type=="AID")
						{
							table->insertTable(dec_list[i]->id,"ID",$1->id);
							SymbolInfo *tmp = table->searchCurrent(dec_list[i]->id);
							tmp->setArray();
							tmp->setdType($1->id);
							arrList.push_back(dec_list[i]->id+ to_string(table->getCurrentScope()));
						}else
						{
							table->insertTable(dec_list[i]->id,dec_list[i]->type,$1->id);
							SymbolInfo *tmp = table->searchCurrent(dec_list[i]->id);
							tmp->setdType($1->id);
							//varList.push_back(dec_list[i]->id+ to_string(table->getCurrentScope()));
						}
					}					
				}
				//dec_list.clear();
				//fprintf(logout ,"At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n", line_count);
				//fprintf(logout, "%s %s ;\n",$1->id.c_str(),$2->id.c_str());
				$$->setID($1->id+" "+$2->id +";");
			}
			;
 		 
type_specifier	: INT	{	
				$$ = new SymbolInfo();
				//fprintf(logout ,"At line no: %d type_specifier	: INT\n", line_count);
				//fprintf(logout, "int\n");
				$$->setID("int");
			}
 		| FLOAT	{
			 	$$ = new SymbolInfo();
				//fprintf(logout ,"At line no: %d type_specifier	: FLOAT\n", line_count);
				//fprintf(logout, "float\n");
				$$->setID("float");
		 }
 		| VOID	{
			 	$$ = new SymbolInfo();
				//fprintf(logout ,"At line no: %d type_specifier	: VOID\n", line_count);
				//fprintf(logout, "void\n");
				$$->setID("void");
		 }
 		;
 		
declaration_list : declaration_list COMMA ID
			{
				$$ = new SymbolInfo();
				
				dec_list.push_back(new SymbolInfo($3->id+to_string(table->getCurrentScope()), "ID"));
				//table->insertTable($3->id,$3->type);
				//fprintf(logout ,"At line no: %d declaration_list : declaration_list COMMA ID\n", line_count);
				//fprintf(logout, "%s , %s\n",$1->id.c_str(),$3->id.c_str());
				$$->setID($1->id+" , "+$3->id);
				
				varList.push_back($3->id + to_string(table->getCurrentScope()));
				
			
			}
			| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
			{
				$$ = new SymbolInfo();
					
				dec_list.push_back(new SymbolInfo($3->id+to_string(table->getCurrentScope()), "AID"));
				//table->insertTable($3->id,$3->type);
				//fprintf(logout ,"At line no: %d declaration_list : declaration_list COMMA ID\n", line_count);
				//fprintf(logout, "%s , %s[%s]\n",$1->id.c_str(),$3->id.c_str(),$5->id.c_str());
				$$->setID($1->id+" , "+$3->id+"["+$5->id+"]");

				arrList.push_back($3->id + to_string(table->getCurrentScope()));
			}
			| ID 
			{
				$$ = new SymbolInfo();

				dec_list.push_back(new SymbolInfo($1->id, "ID"));	
				//table->insertTable($1->id,$1->type);
				//fprintf(logout ,"At line no: %d declaration_list : ID\n", line_count);
				//fprintf(logout, "%s\n",$1->id.c_str());
				varList.push_back($1->id + to_string(table->getCurrentScope()));
				$$->setID($1->id);
			}
			| ID LTHIRD CONST_INT RTHIRD
			{
				$$ = new SymbolInfo();
					
				dec_list.push_back(new SymbolInfo($1->id, "AID"));
				//table->insertTable($1->id,$1->type);
				//fprintf(logout ,"At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n", line_count);
				//fprintf(logout, "%s[%s]\n",$1->id.c_str(),$3->id.c_str());
				$$->setID($1->id+"["+$3->id+"]");

				arrList.push_back($1->id + to_string(table->getCurrentScope()));
			}
			;
 		  
statements : statement
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d statements : statement\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
	   | statements statement
	   {
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d statements : statements statement\n", line_count);
			//fprintf(logout, "%s \n%s\n",$1->id.c_str(),$2->id.c_str());
			$$->setID($1->id+"\n"+$2->id);
			$$->code += $2->code;
			//fprintf(logout, "%s \n",$$->code.c_str());	
	   }
	   ;
	   
statement : var_declaration
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d statement : var_declaration\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
	  | expression_statement
	  {
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d statement : expression_statement\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);

			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  | compound_statement
	  {
		 	$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d statement : compound_statement\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);

			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		 	$$ = new SymbolInfo($3);
			//fprintf(logout ,"At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n", line_count);
			//fprintf(logout, "for(%s %s %s) %s \n",$3->id.c_str(),$4->id.c_str(),$5->id.c_str(),$7->id.c_str());
			$$->setID("for("+$3->id+$4->id+$5->id+") "+$7->id);

			char *temp = newTemp();
			char *label1 = newLabel(); 
			char *label2 = newLabel();

			$$->code += string(label1) + ":\n";  
			$$->code += $4->code; 
			$$->code += "mov ax, " + $4->id+"\n";  
			$$->code += "cmp ax, 0\n";  
			$$->code += "je " + string(label2)+"\n";  
			$$->code += $7->code;
			$$->code += $5->code;
			$$->code += "jmp " + string(label1) + "\n";
			$$->code += string(label2) + ":\n"; 

			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  { 
		  	//cout<<"inside just if"<<endl;
		 	$$ = new SymbolInfo($3);
			//fprintf(logout ,"At line no: %d statement : IF LPAREN expression RPAREN statement\n", line_count);
			//fprintf(logout, "if( %s ) %s \n",$3->id.c_str(),$5->id.c_str());
			$$->setID("if( "+$3->id+" ) "+$5->id);

			char *label1 = newLabel();

			$$->code += "mov ax, "+$3->symbol + "\n";
			$$->code += "cmp ax, 0\n";
			$$->code += "je "+ string(label1) + "\n";
			$$->code += $5->code;
			$$->code += string(label1) + ":\n";
			//fprintf(logout, "%s \n",$$->code.c_str());	
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		  	//cout<<"inside if else"<<endl;
		 	$$ = new SymbolInfo($3);
			//fprintf(logout ,"At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n", line_count);
			//fprintf(logout, "if( %s ) %s \nelse %s \n",$3->id.c_str(),$5->id.c_str(),$7->id.c_str());
			$$->setID("if( "+$3->id+" ) "+$5->id +" \nelse "+$7->id);

			$$->code += $3->code;
			char *label1 = newLabel();
			char *label2 = newLabel();
			$$->code += "mov ax, "+$3->symbol+"\n";
			$$->code += "cmp ax, 0\n";
			$$->code += "je "+string(label1)+"\n";
			$$->code += $5->code + "jmp " + string(label2)+"\n"+string(label1)+":\n";
			$$->code += $7->code+":\n";
			$$->code += string(label2)+":\n";

			//fprintf(logout, "%s \n",$$->code.c_str());
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {	  
		 	$$ = new SymbolInfo();
			//fprintf(logout ,"At line no: %d statement : WHILE LPAREN expression RPAREN statement\n", line_count);
			//fprintf(logout, "while( %s ) %s \n",$3->id.c_str(),$5->id.c_str());
			$$->setID("while( "+$3->id+" ) "+$5->id);

			char *temp = newTemp();
			char *label1 = newLabel(); 
			char *label2 = newLabel();

			$$->code += string(label1) + ":\n";  
			$$->code += $3->code; 
			$$->code += "mov ax, " + $3->symbol+"\n";  
			$$->code += "cmp ax, 0\n";  
			$$->code += "je " + string(label2)+"\n";
			$$->code += $5->code;
			$$->code += "jmp " + string(label1) + "\n";
			$$->code += string(label2) + ":\n"; 

			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		 	$$ = new SymbolInfo($3);
			//fprintf(logout ,"At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n", line_count);
			//fprintf(logout, "println( %s ); \n",$3->id.c_str());
			$$->setID( "println( " + $3->id + " )" );
			
			$$->code += "mov dx, "+ $3->id + to_string(table->getCurrentScope())+"\n";
			//varList.push_back($3->id+ to_string(table->getCurrentScope()));
			$$->code += "call printProc\n";
			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  | RETURN expression SEMICOLON
	  {
		 	$$ = new SymbolInfo($2);
			//fprintf(logout ,"At line no: %d statement : RETURN expression SEMICOLON\n", line_count);
			//fprintf(logout, "return %s ;\n",$2->id.c_str());
			$$->setID( "return "+$2->id+";" );
			$$->setdType($2->dType);

			$$->code+= "mov ax, "+$2->symbol+"\n";
			$$->code+= "mov "+currentFunc+"_return"+", ax\n";
			$$->code+= "jmp end_of_"+currentFunc + "\n";

			//$$->setSymbol(currentFunc+"_return");
			$$->symbol = currentFunc+"_return";
			//fprintf(logout, "%s\n",$$->code.c_str());
	  }
	  ;
	  
expression_statement 	: SEMICOLON	
			{
				$$ = new SymbolInfo();
				//fprintf(logout ,"At line no: %d expression_statement 	: SEMICOLON	\n", line_count);
				//fprintf(logout, ";\n");
				$$->setID(";" );
			}		
			| expression SEMICOLON 
			{
				$$ = new SymbolInfo($1);
				//fprintf(logout ,"At line no: %d expression_statement 	: expression SEMICOLON	\n", line_count);
				//fprintf(logout, "%s ;\n",$1->id.c_str());
				$$->setID($1->id+";" );	

				//fprintf(logout, "%s \n",$$->code.c_str());	
			}
			;
	  
variable : ID 	
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d variable : ID	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			
			$$->setID($1->id);
			//$$->setSymbol($1->id+to_string(table->getCurrentScope()));
			$$->symbol = $1->id + to_string(table->getCurrentScope());
			//varList.push_back($1->id+ to_string(table->getCurrentScope()));

			SymbolInfo *tmp = table->searchTable($1->id);
			if(tmp == NULL)
			{
				errCount++;
				fprintf(logout ,"Error at line no: %d Undeclared variable.	\n", line_count);
			}else
			{
				$$->setdType(tmp->dType);
				if(tmp->isArr)
				{
					errCount++;
					//fprintf(logout ,"Error at line no: %d Type mismatch.	\n", line_count);
				}
			}
		}
	 	| ID LTHIRD expression RTHIRD 
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d variable : ID LTHIRD expression RTHIRD	\n", line_count);
			//fprintf(logout, "%s[%s] \n",$1->id.c_str(),$3->id.c_str());
			$$->setID($1->id+"["+$3->id+"]");	


			if($3->dType != "int")
			{
				errCount++;
				fprintf(logout ,"Error at line no: %d Non Integer array indexing.	\n", line_count);
			}

			SymbolInfo *tmp = table->searchTable($1->id);
			if(tmp == NULL)
			{
				errCount++;
				fprintf(logout ,"Error at line no: %d Undeclared ID.	\n", line_count);
			}else
			{
				if(!tmp->isArr)
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Index used with variable.	\n", line_count);
				}else
				{
					$$->isArr = true;
					$$->setdType(tmp->dType);
					$$->code+="mov bx, "+$3->symbol+"\n";
					//$$->setSymbol($1->id+to_string(table->getCurrentScope()));
					$$->symbol = $1->id+to_string(table->getCurrentScope());
					//arrList.push_back($1->id+ to_string(table->getCurrentScope()));
				}
			}

			fprintf(logout, "%s\n",$$->code.c_str());	 
		}
	 	;
	 
 expression : logic_expression
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d expression : logic_expression	\n", line_count);
			fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
	    | variable ASSIGNOP logic_expression
		{
			$$ = new SymbolInfo($3);
			//fprintf(logout ,"At line no: %d expression : variable ASSIGNOP logic_expression	\n", line_count);
			//fprintf(logout, "%s = %s\n",$1->id.c_str(),$3->id.c_str());
			$$->setID($1->id + " = " + $3->id);
			$$->setdType($1->dType);
			$$->code += $1->code;

			//cout<<$1->id<<" "<< $1->dType<<endl;
			//cout<<$3->id<<" "<< $3->dType<<endl;



			
			if($1->dType != $3->dType)
			{
				errCount++;
				//fprintf(errorout ,"Error at line no: %d Type mismatch.	\n", line_count);
			}

			$$->code += "mov ax, "+$3->symbol +"\n";
			//cout<<$$->isArr;
			if($1->isArr)
			{
				$$->code += "mov "+$1->symbol+"[bx], ax\n";
			}else
			{
				$$->code += "mov "+$1->symbol+", ax\n";				
			}

			//fprintf(logout ,"%s", $$->code.c_str());
		} 	
	    ;
			
logic_expression : rel_expression 	
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d logic_expression : rel_expression	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);	

			//fprintf(logout, "%s \n",$$->code.c_str());		
		}
		| rel_expression LOGICOP rel_expression
		{
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d logic_expression : rel_expression LOGICOP rel_expression	\n", line_count);
			//fprintf(logout, "%s %s %s\n",$1->id.c_str(),$2->id.c_str(),$3->id.c_str());
			$$->setID($1->id+" "+$2->id+" "+$3->id);
			$$->setdType("int");

			char *label1 = newLabel();
			char *label2 = newLabel();
			char *temp = newTemp();
			if($2->id == "&&")
			{
				$$->code += "mov ax, "+$1->symbol+"\n";
				$$->code += "cmp ax, 0\n";
				$$->code += "je "+string(label1)+"\n";
				$$->code += "mov ax, "+$3->symbol+"\n";
				$$->code += "cmp ax, 0\n";
				$$->code += "je "+string(label1)+"\n";
				$$->code += "mov "+string(temp) +", 1\n";
				$$->code += "jmp "+string(label2)+":\n";
				$$->code += string(label1)+":\n";
				$$->code += "mov "+string(temp) +", 0\n";
				$$->code += string(label2)+":\n";
			}else
			{
				$$->code += "mov ax, "+$1->symbol+"\n";
				$$->code += "cmp ax, 1\n";
				$$->code += "je "+string(label1)+"\n";
				$$->code += "mov ax, "+$3->symbol+"\n";
				$$->code += "cmp ax, 1\n";
				$$->code += "je "+string(label1)+"\n";
				$$->code += "mov "+string(temp) +", 0\n";
				$$->code += "jmp "+string(label2)+":\n";
				$$->code += string(label1)+":\n";
				$$->code += "mov "+string(temp) +", 1\n";
				$$->code += string(label2)+":\n";
			}

			//$$->setSymbol(temp);
			$$->symbol = string(temp);
			//fprintf(logout, "%s\n",$$->code.c_str());
		} 	
		;
			
rel_expression	: simple_expression
		{	
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d rel_expression	: simple_expression	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
		| simple_expression RELOP simple_expression	
		{	
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d  rel_expression	: simple_expression RELOP simple_expression	\n", line_count);
			//fprintf(logout, "%s %s %s\n",$1->id.c_str(),$2->id.c_str(),$3->id.c_str());
			$$->setID($1->id+" "+$2->id+" "+$3->id);
			$$->setdType("int");

			$$->code += "mov ax, "+$1->symbol+"\n";
			$$->code += "cmp ax, "+$3->symbol + "\n";

			char *temp = newTemp();
			char *label1 = newLabel();
			char *label2 = newLabel();
			string l = string(label2);

			if($2->id == ">")
			{
				$$->code += "jg "+string(label1) + "\n";
			}else if($2->id == ">=")
			{
				$$->code += "jge "+string(label1) + "\n";
			}else if($2->id == "<")
			{
				$$->code += "jl "+string(label1) + "\n";
			}else if($2->id == "<=")
			{
				$$->code += "jle "+string(label1) + "\n";
			}else if($2->id == "==")
			{
				$$->code += "je "+string(label1) + "\n";
			}else if($2->id == "!=")
			{
				$$->code += "jne "+string(label1) + "\n";
			}

			$$->code += "mov "+ string(temp)+", 0\n";
			$$->code += "jmp "+ string(label2)+"\n";
			$$->code +=string(label1) + ":\n";
			$$->code += "mov "+ string(temp) + ", 1\n"+string(label2)+":\n";
			//$$->code += string(label2);
			
			//$$->setSymbol(temp);
			$$->symbol = string(temp);
			//fprintf(logout, "%s\n",$$->code.c_str());
		}
		;
				
simple_expression : term 
		{			
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d simple_expression : term	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);	

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
   		| simple_expression ADDOP term
		{			
			$$ = new SymbolInfo($1);
			$$->code += $3->code;
			//fprintf(logout ,"At line no: %d simple_expression : simple_expression ADDOP term	\n", line_count);
			//fprintf(logout, "%s %s %s\n",$1->id.c_str(),$2->id.c_str(),$3->id.c_str());
			$$->setID($1->id+" "+$2->id+" "+$3->id);	
			$$->setdType($3->dType);

			if($1->dType  == "void" || $3->dType == "void")
			{
				if($1->dType  == "void")
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Void type %s used in expression.\n", line_count,$1->id.c_str());
				}
				if($3->dType  == "void")
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Void type %s used in expression.\n", line_count, $3->id.c_str());
				}
			}

			$$->code += "mov ax, "+$1->symbol+"\n";
			$$->code+= "add ax, " + $3->symbol+"\n";

			char *temp = newTemp();
			$$->code+= "mov "+string(temp) +", ax\n";
			//$$->setSymbol(string(temp));

			//fprintf(logout ,"%s", $$->code.c_str());	
	    }
	    ;
					
term 	:	unary_expression
		{			
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d term :	unary_expression	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);	

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
     	|  term MULOP unary_expression
		{			
			$$ = new SymbolInfo($1);
			$$->code += $3->code;
			//fprintf(logout ,"At line no: %d term : term MULOP unary_expression	\n", line_count);
			//fprintf(logout, "%s %s %s\n",$1->id.c_str(),$2->id.c_str(),$3->id.c_str());
			$$->setID($1->id+" "+$2->id+" "+$3->id);
			$$->setdType($1->dType);

			if($2->id == "%")
			{
				if($1->dType != "int" || $3->dType != "int")
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Non Integer operand on modulus operator.\n", line_count);
				}

				$$->code += "mov ax, "+$1->symbol +"\n";
				$$->code += "div ax, "+$3->symbol +"\n";

				char *temp = newTemp();
				$$->code += "mov "+string(temp)+", dx\n";
				//$$->setSymbol(temp);
				$$->symbol = string(temp);
			}else if($2->id == "*")
			{
				$$->code += "mov ax, "+$1->symbol +"\n";
				$$->code += "mul ax, "+$3->symbol +"\n";

				char *temp = newTemp();
				$$->code += "mov "+string(temp)+", ax\n";
				//$$->setSymbol(temp);
				$$->symbol = string(temp);
			}else if($2->id == "/")
			{
				$$->code += "mov ax, "+$1->symbol +"\n";
				$$->code += "div ax, "+$3->symbol +"\n";

				char *temp = newTemp();
				$$->code += "mov "+string(temp)+", ax\n";
				//$$->setSymbol(temp);
				$$->symbol = string(temp);
			}
			
			if($1->dType  == "void" || $3->dType == "void")
			{
				if($1->dType  == "void")
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Void type %s used in expression.\n", line_count,$1->id.c_str());
				}
				if($3->dType  == "void")
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Void type %s used in expression.\n", line_count, $3->id.c_str());
				}
			}

			//fprintf(logout ,"%s", $$->code.c_str());
		}
     	;

unary_expression : ADDOP unary_expression 
		{			
			$$ = new SymbolInfo($2);
			//fprintf(logout ,"At line no: %d unary_expression : ADDOP unary_expression \n", line_count);
			//fprintf(logout, "%s %s\n",$1->id.c_str(),$2->id.c_str());
			$$->setID($1->id+" "+$2->id);	
			$$->setdType($2->dType);

			if($2->dType  == "void")
			{
				errCount++;
				fprintf(logout ,"Error at line no: %d Void type %s used in expression.\n", line_count, $2->id.c_str());
			}
		}
		| NOT unary_expression 
		{			
			$$ = new SymbolInfo($2);
			//fprintf(logout ,"At line no: %d unary_expression : NOT unary_expression \n", line_count);
			//fprintf(logout, "%s %s\n",$1->id.c_str(),$2->id.c_str());
			$$->setID($1->id+" "+$2->id);
			$$->setdType($2->dType);

			if($2->dType  == "void")
			{
				errCount++;
				//fprintf(errorout ,"Error at line no: %d Void type %s used in expression.\n", line_count, $2->id.c_str());
			}
		}
		| factor 
		{			
			$$ = new SymbolInfo($1);
			//fprintf(logout ,"At line no: %d unary_expression :factor 	\n", line_count);
			//fprintf(logout, "%s\n",$1->id.c_str());
			$$->setID($1->id);
			$$->setdType($1->dType);

			//fprintf(logout, "%s \n",$$->code.c_str());	
		}
		;
	
factor	: variable 
	{			
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d factor	: variable  	\n", line_count);
		//fprintf(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);
		$$->setdType($1->dType);

		char *temp = newTemp();
		if($1->isArr)
		{
			$$->code += "mov ax, " + $1->symbol + "[bx]\n";
			$$->code += "mov " + string(temp) + ", ax";
			//$$->setSymbol()
			$$->symbol = string(temp);
		}else
		{
			$$->code += "mov ax, " + $1->symbol+"\n";
			$$->code += "mov " + string(temp) +", ax\n";
			$$->symbol = string(temp);
		}

		//fprintf(logout, "%s \n",$$->code.c_str());		
	}
	| ID LPAREN argument_list RPAREN
	{			
		$$ = new SymbolInfo();
		//fprintf(logout ,"At line no: %d factor	: ID LPAREN argument_list RPAREN  	\n", line_count);
		//fprintf(logout, "%s ( %s )\n",$1->id.c_str(),$3->id.c_str());
		$$->setID($1->id + " ( " + $3->id +" )" );


		SymbolInfo *tmp = table->searchTable($1->id);
		vector<string> list = tmp->getParaList();
		for(int i=0; i<list.size(); i++)
		{
			$$->code += "mov ax, "+arg_name[i] + "\n";
			$$->code += "mov "+list[i] + ", ax\n";
		}

		char *temp = newTemp();
		$$->code+="call "+$1->id+"\n";
        $$->code+="mov ax,"+$1->id+"_return_val\n";
        $$->code += "mov "+string(temp)+", ax\n";
        $$->symbol = string(temp);

		//fprintf(logout, "%s \n",$$->code.c_str());		
	

		if(tmp)
		{
			if(tmp->isFunc)
			{
				if(tmp->para_num == arg_list.size())
				{
					bool hello = false;
					for(int i=0; i<tmp->para_num; i++)
					{
						if(tmp->paraType[i] != arg_list[i])
						{
							hello = true;							
						}
					}

					if(hello)
					{
						errCount++;
						fprintf(logout ,"Error at line no: %d Mismatched function call.\n", line_count);
					}else
					{
						$$->setdType(tmp->dType);
					}
				}else
				{
					errCount++;
					fprintf(logout ,"Error at line no: %d Mismatched function call.\n", line_count);
				}
			}
			else
			{
				errCount++;
				fprintf(logout ,"Error at line no: %d Undefined function %s called.\n", line_count, $1->id.c_str());
			}
		}else
		{
			errCount++;
			fprintf(logout ,"Error at line no: %d Undefined function %s called.\n", line_count, $1->id.c_str());
		}

		arg_list.clear();
		arg_name.clear();
	}
	| LPAREN expression RPAREN
	{			
		$$ = new SymbolInfo($2);
		//fprintf(logout ,"At line no: %d factor	: LPAREN expression RPAREN  	\n", line_count);
		//fprintf(logout, " ( %s )\n",$2->id.c_str());
		$$->setID(" ( " + $2->id +" )" );
		$$->setdType($2->dType);	

		//fprintf(logout, "%s \n",$$->code.c_str());
	}
	| CONST_INT 
	{			
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d factor	: CONST_INT \n", line_count);
		//fprintf(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);
		$$->setdType("int");	

		char *temp = newTemp();
		$$->code += "mov "+ string(temp) + ", "+ $1->id+"\n";
		//$$->setSymbol(temp);
		$$->symbol = string(temp);
		//fprintf(logout, "%s\n",$$->code.c_str());			
	}
	| CONST_FLOAT
	{			
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d factor	: CONST_FLOAT \n", line_count);
		//(logout, "%s\n",$1->id.c_str());
		$$->setID($1->id);
		$$->setdType("float");

		char *temp = newTemp();
		$$->code += "mov "+ string(temp) + ", "+ $1->id+"\n";
		//$$->setSymbol(temp);
		$$->symbol = string(temp);
		//fprintf(logout, "%s\n",$$->code.c_str());
	}
	| variable INCOP 
	{			
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d factor	: variable INCOP \n", line_count);
		//fprintf(logout, "%s++\n",$1->id.c_str());
		$$->setID($1->id + "++");	
		$$->setType($1->type);

		if($1->isArr)
		{
			$$->code+= "inc "+$1->symbol+"[bx]\n";
		}else
		{
			$$->code+= "inc "+$1->symbol+"\n";
		}	
		$$->setSymbol($1->id);
		//fprintf(logout, "%s\n",$$->code.c_str());
	}
	| variable DECOP
	{				
		$$ = new SymbolInfo($1);
		//fprintf(logout ,"At line no: %d factor	: variable DECOP \n", line_count);
		//fprintf(logout, "%s--\n",$1->id.c_str());
		$$->setID($1->id + "--");	
		$$->setType($1->type);	

		if($1->isArr)
		{
			$$->code+= "dec "+$1->symbol+"[bx]\n";
		}else
		{
			$$->code+= "dec "+$1->symbol+"\n";
		}	

		//fprintf(logout, "%s\n",$$->code.c_str());	
	}
	;
	
argument_list 	: arguments
				{			
					$$ = new SymbolInfo($1);
					//fprintf(logout ,"At line no: %d argument_list 	: arguments \n", line_count);
					//fprintf(logout, "%s\n",$1->id.c_str());
					$$->setID($1->id);	

					//fprintf(logout, "%s \n",$$->code.c_str());		
				}
			  	| 
				{
					$$ = new SymbolInfo();
					//fprintf(logout ,"At line no: %d argument_list 	: arguments \n", line_count);
					//fprintf(logout, "\n");
					$$->setID("");
				}
			  	;
	
arguments 	: arguments COMMA logic_expression
			{			
				$$ = new SymbolInfo($1);
				$$->code += $3->code;
				//fprintf(logout ,"At line no: %d arguments 	: arguments COMMA logic_expression \n", line_count);
				//fprintf(logout, "%s , %s\n",$1->id.c_str(),$3->id.c_str());
				$$->setID($1->id + " , " + $3->id);	
				arg_list.push_back($3->dType);		
				arg_name.push_back($3->id+ to_string(table->getCurrentScope()));
				//varList.push_back($3->id+ to_string(table->getCurrentScope()));	

				//fprintf(logout, "%s \n",$$->code.c_str());
			}
	      	| logic_expression
			{			
				$$ = new SymbolInfo($1);
				//fprintf(logout ,"At line no: %d arguments 	: logic_expression \n", line_count);
				//fprintf(logout, "%s \n",$1->id.c_str());
				$$->setID($1->id);
				arg_list.push_back($1->dType);
				arg_name.push_back($1->id+ to_string(table->getCurrentScope()) );
				//varList.push_back($1->id+ to_string(table->getCurrentScope()));

				//fprintf(logout, "%s \n",$$->code.c_str());	
			}
	      	;
 

%%

vector<string> stringSplit(string str, char delim){
   vector<string> tokens;
   tokens.clear();

   string index;
   istringstream tStream(str);

   while (getline(tStream, index, delim))
   {
      tokens.push_back(index);
   }

   return tokens;
}


bool compare(string s1, string s2, int n)
{
     vector<string> first1 = stringSplit(s1,' ');
     vector<string> second1 = stringSplit(s2,' ');

     vector<string> first2 = stringSplit(first1[1],',');
     vector<string> second2 = stringSplit(second1[1],',');

     if(first2[0]==second2[1])
	 {
		 n++;
		 if(first2[1]==second2[0])
		 {
			 return 1;
		 }
	 }else
	 {
		 n--;
		 return 0;
	 }


     return false;
}

void optimize(int n)
{
    ifstream input("code.asm");
    string str1,str2;
    getline(input, str2);
    bool hello = false;

    while( getline(input, str1))
	{
    	if(hello)
		{
        	str2 = str1;
        	hello = false;
        	continue;
    	}

    	if(str1[0] == 'm')
		{
			if(str2[0] == 'm')
			{
				if(compare(str2, str1,n))
				{
					hello = true ;
					continue;
				}
			}
    	}
	
    	fprintf(optout,"%s\n",str2.c_str());

		str2 = str1;
	}


	fprintf(optout, "end main\n");
}



int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	yyin=fp;
	logout = fopen("160543_log.txt" ,"w");
	//errorout = fopen("160543_error.txt" ,"w");
	//codeOut = fopen("Code.txt","w");
	optout = fopen("optimizedCode.asm","w");
	yyparse();
	
		
	return 0;
}

