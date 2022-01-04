#include<bits/stdc++.h>

using namespace std;

#define NULL_VALUE -99999
#define SUCCESS_VALUE 99999



class SymbolInfo
{
public:
    string id = "", type = "",dType = "";
    int scope, column, pos;
    SymbolInfo *next, *prev;
    bool isFunc = false;
    bool isDef = false;
    bool isDec = false;
    int para_num = 0;
    vector<string> paraList;
    vector<string> paraType;

    bool isArr = false;

    string symbol="";
    string code="";

    void setSymbol(string s){ this->symbol = s;}
    string getSymbol(){ return this->symbol;}

    SymbolInfo()
    {
        
    }

    /*SymbolInfo(SymbolInfo *a)
    {
        this->symbol = a->symbol;
        this->code = a->code;
    }*/

    SymbolInfo(string n, string t, string d, int s, int c)
    {
        scope = s;
        column = c;
        id = n;
        type = t;
        dType = d;
        next = NULL;
        prev = NULL;
    }

    SymbolInfo(string n, string t, string d="")
    {
        id = n;
        type = t;
        dType = d;
        next = NULL;
        prev = NULL;
    }

    SymbolInfo(SymbolInfo *s)
    {
        this->id = s->id;
        this->type = s->type;
        this->dType = s->dType;
        this->scope = s->scope;
        this->column = s->column;
        this->pos = s->pos;
        this->next = s->next;
        this->prev = s->prev;

        this->symbol = s->symbol;
        this->code = s->code;
    }

    string getID()
    {
        return this->id;
    }
    string getType()
    {
        return this->type;
    }
    string getDtype()
    {
        return this->dType;
    }
    void setID(string s)
    {
        this->id = s;
    }
    void setType(string s)
    {
        this->type = s;
    }
    void setdType(string s)
    {
        this->dType = s;
    }

    bool isFunction()
    {
        return this->isFunc;
    }
    void setFunc()
    {
        this->isFunc = true;
    }
    bool isDeclared()
    {
        return this->isDec;
    }
    bool isDefined()
    {
        return this->isDef;
    }
    void setDefined()
    {
        this->isDef = true;
    }
    void setDeclared()
    {
        this->isDec = true;
    }
    void setParaList(vector<string> list)
    {
        this->paraList = list;
    }
    void setParaType(vector<string> list)
    {
        para_num = list.size();
        this->paraType = list;
    }
    vector<string> getParaList()
    {
        return this->paraList;
    }
    vector<string> getParaType()
    {
        return this->paraType;
    }
    bool isArray()
    {
        return this->isArr;
    }
    void setArray()
    {
        this->isArr = true;
    }
};

class tableColumn
{

public:
    int columnId;
    SymbolInfo *head;

    tableColumn()
    {
        columnId = -1;
        head = NULL;
    }

    int insertLast(string item, string type, string dtype, int s)
    {
        SymbolInfo* temp;
        SymbolInfo* newNode = new SymbolInfo(item, type, dtype, s, columnId);

        //newNode ->id = item;
        temp = head;

        if(temp == NULL)
        {
            head = newNode;
            head->pos = 0;
            return SUCCESS_VALUE;
        }

        while(temp->next != NULL)
        {
            temp = temp->next;
        }

        temp->next = newNode;
        newNode->prev = temp;
        newNode->next = NULL;
        newNode->pos = (newNode->prev->pos) + 1;

        return SUCCESS_VALUE;
    }

    int deleteItem(string item)
    {
        SymbolInfo *temp, *prev ;
        temp = head ;
        while (temp != 0)
        {
            if (temp->id == item) break ;
            prev = temp;
            temp = temp->next ;
        }

        if (temp == 0)
            return NULL_VALUE ;

        if (temp == head)
        {
            head = head->next ;
            delete temp;
        }
        else
        {
            prev->next = temp->next ;
            delete temp;
        }
        return SUCCESS_VALUE ;
    }

    SymbolInfo* searchItem(string item)
    {
        SymbolInfo* temp = head;

        while(temp != NULL)
        {
            if (temp->id == item)
            {
                return temp;
            }

            temp = temp->next;
        }

        return NULL;
    }

    void printList(FILE *fp) const
    {
        SymbolInfo * temp;
        temp = head;
        while(temp!=0)
        {
            //cout<< " <" << temp->id << ", "<< temp->type <<"> "<<" -- ";
            fprintf(fp,"<%s,%s> -- ",temp->id.c_str(),temp->type.c_str());
            temp = temp->next;
        }
        fprintf(fp,"\n");
    }

    bool isEmpty()
    {
        if(this->head== NULL)
            return true;
        return false;
    }
};

class scopeTable
{
public:
    int scopeId, size;
    tableColumn *columnList;
    scopeTable *parent;

    scopeTable(int len, int scope)
    {
        scopeId = scope;
        size=len;
        columnList = new tableColumn[len];
        for(int i=0; i<size; i++)
        {
            columnList[i].columnId = i;
        }
    }

    int Hash(string s)
    {
        int i, sum = 0;
        for (i=0; i < s.length(); i++)
            sum += s[i];

        return ((sum % size)+size)%size;
    }

    void insertColumn(string item, string type, string dtype = "")
    {
        SymbolInfo *fnd = searchColumn(item);
        if(fnd)
        {
            //cout<<"Item alrady exists in the current scope"<<endl;
            return;
        }
        int index = Hash(item);
        int check;
        if(index<size)
        {
            ///*******************
            //cout<<"here 1"<<endl;
            check = columnList[index].insertLast(item, type, dtype, scopeId);
            //cout<<"here 2"<<endl;
        }

        //if(check = SUCCESS_VALUE)
            //cout<<"Item successfully added to Position : "<<index<<", on Scope table : "<<scopeId<<endl;
    }

    SymbolInfo* searchColumn(string s)
    {
        int index=Hash(s);
        if(index<size)
        {
            SymbolInfo *n=columnList[index].searchItem(s);
            if(n) return n;
            else return NULL;
        }
        return NULL;
    }

    void deleteColumn(string s)
    {
        SymbolInfo *fnd = searchColumn(s);
        if(fnd==NULL)
        {
            //cout<<"Item not found"<<endl;
            return;
        }
        int index = Hash(s);
        if(index!=-1)
        {
            columnList[index].deleteItem(s);
            //cout<<"item deleted successfully."<<endl;
        }
        //else cout<<"Item is not in the table"<<endl;
    }

    void printScopeTable(FILE *fp)
    {
        //cout<< "Scope table #"<< scopeId<<endl;
        fprintf(fp,"Scope table #%d\n",scopeId);
        for(int i=0; i<size; i++)
        {
            if(!columnList[i].isEmpty())
            {
                //cout<<i<<": ";
                fprintf(fp,"%d:    ",i);
                columnList[i].printList(fp);
                //cout<<endl;
            }
        }
    }
};

class symbolTable
{
public:
    int len;
    int scopeCount = 0;
    scopeTable *head, *current;

    symbolTable(int l)
    {
        scopeCount = 1;
        len = l;
        head = new scopeTable(l,scopeCount);
        current = head;
    }

    void newScope(FILE *fp)
    {
        scopeCount++;
        scopeTable *newSc = new scopeTable(len,scopeCount);
        newSc->parent = current;
        current = newSc;
        fprintf(fp,"\nScope table with id: %d successfully created.\n",current->scopeId);
        //cout<<"Scope table with id: "<<current->scopeId<<" successfully created."<<endl;
    }

    void exitScope(FILE *fp)
    {
        if(current == 0)
        {
            //cout<<"Table is empty."<<endl;
            return;
        }
        //cout<<"Scope Table with id: "<<current->scopeId<<" removed."<<endl;
        fprintf(fp,"\nScope table with id: %d successfully removed.\n",current->scopeId);
        current = current->parent;
    }

    void printAll(FILE *fp)
    {
        scopeTable *temp = current;
        //if(current==0)
            //cout<<"Table is empty."<<endl;
        while(temp)
        {
            temp->printScopeTable(fp);
            //cout<<endl;
            temp = temp->parent;
            fprintf(fp,"\n\n");
        }
    }

    void printCurrent(FILE *fp)
    {
        //cout<<"herePrint"<<endl;
        if(current!=0)
            current->printScopeTable(fp);
        //else
            //cout<<"Table is empty."<<endl;
    }

    void insertTable(string item, string type, string dtype = "")
    {
        //cout<<"inserted"<<endl;
        if(current!=0)
            current->insertColumn(item, type,dtype);
    }

    SymbolInfo* searchTable(string key)
    {
        scopeTable *temp = current;
        while(temp!= 0)
        {
            SymbolInfo *fnd = temp->searchColumn(key);
    
            if(fnd)
            {
                //cout<<"Item found at position: "<<fnd->column<<","<<fnd->pos<<"- on Scope table: "<<fnd->scope<<endl;
                return fnd;
            }
            temp = temp->parent;
        }
        return NULL;
    }

    SymbolInfo* searchCurrent(string key)
    {
        return current->searchColumn(key);
    }

    void deleteTable(string key)
    {
        if(current)
            current->deleteColumn(key);
    }

    int getCurrentScope()
    {
        return this->scopeCount;
    }

};
