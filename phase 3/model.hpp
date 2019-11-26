
#include <vector>
#include <string>
#include <iostream>
#include <sstream>

class Generator
{
  public:
    static int counter_label;
    static int counter_var;

    static void init()
    {
        counter_label = 0;
        counter_var = 0;
    }

    static std::string make_label()
    {
        std::string temp = "__label__";
        temp += std::to_string(counter_label++);
        return temp;
    }

    static std::string make_var()
    {
        std::string temp = "__temp__";
        temp += std::to_string(counter_var++);
        return temp;
    }
};

class ASTNode
{
  public:
    virtual std::string gencode() = 0;
};

class Expr : public ASTNode
{
  public:
    Expr(Expr *p1, std::string op, Expr *p2) : p1(p1), op(op), p2(p2) {}
    virtual ~Expr()
    {
        delete p1;
        delete p2;
    }

    virtual std::string gencode()
    {
        std::stringstream ss;
        ss << p1->gencode() << p2->gencode();
        std::string temp = Generator::make_var();
        ss << op << ' ' << temp << ", " << p1->ret_var << ", " << p2->ret_var << '\n';
        ret_var = temp;
        return ss.str();
    }

    std::string ret_var;

  protected:
    Expr() {}
    Expr *p1 = nullptr, *p2 = nullptr;
    std::string op;
};

class ExprID : public Expr
{
  public:
    ExprID(std::string name) : name(name) {}
    virtual std::string gencode()
    {
        ret_var = name;
        return "";
    }

  protected:
    std::string name;
};

class ExprNumber : public Expr
{
  public:
    ExprNumber(int number) : number(number) {}
    virtual std::string gencode()
    {
        std::string temp = Generator::make_var();
        ret_var = temp;
        std::stringstream ss;
        ss << "= " << temp << ", " << std::to_string(number) << '\n';
        return ss.str();
    }

  protected:
    int number;
};

class Statement : public ASTNode
{
};

class StatementList : public ASTNode
{
  public:
    StatementList() {}
    virtual ~StatementList()
    {
        for (auto s : stat_vec)
        {
            delete s;
        }
    }
    void append(Statement *s) { stat_vec.push_back(s); }

    virtual std::string gencode() {
        std::stringstream ss;
        for (auto s : stat_vec) {
            ss << s->gencode();
        }
        return ss.str();
    }

  protected:
    std::vector<Statement *> stat_vec;
};

class IfElseStatement : public Statement
{
  public:
    IfElseStatement(Expr *bool_expr, StatementList *then_block, StatementList *else_block)
        : bool_expr(bool_expr), then_block(then_block), else_block(else_block) {}

    virtual std::string gencode() {
        std::stringstream ss;
        ss << bool_expr->gencode();
        std::string l0, l1, l2;
        l0 = Generator::make_label();
        l1 = Generator::make_label();
        l2 = Generator::make_label();

        ss << "?:= " << l0 << ", " << bool_expr->ret_var << '\n';
        ss << ":= " << l1 << '\n';
        ss << ": " << l0 << '\n';
        ss << then_block->gencode();
        ss << ":= " << l2 << '\n';
        ss << ": " << l1 << '\n';
        ss << else_block->gencode();
        ss << ": " << l2 << '\n';
        return ss.str();
    }


  protected:
    Expr *bool_expr;
    StatementList *then_block;
    StatementList *else_block;
};

class ExprStatement : public Statement
{
  public:
    ExprStatement(Expr *expr) : expr(expr) {}
    virtual ~ExprStatement() { delete expr; }

    virtual std::string gencode() {
        return expr->gencode();
    }

  protected:
    Expr *expr;
};

class DefineStatement : public Statement
{
  public:
    DefineStatement(std::string name) : name(name) {}
    DefineStatement(std::string name, Expr *expr) : name(name), expr(expr) {}
    virtual ~DefineStatement() { delete expr; }

    virtual std::string gencode()
    {
        std::stringstream ss;
        ss << ". " << name << '\n';
        if (expr) {
            ss << expr->gencode();
            ss << "= " << name << ", " << expr->ret_var << '\n';
        }
        return ss.str();
    }

  protected:
    std::string name;
    Expr *expr = nullptr;
};
