all: mini_c

mini_c.tab.c mini_c.tab.h:	mini_c.y
	bison -d mini_c.y

lex.yy.c: mini_c.l mini_c.tab.h
	flex mini_c.l

mini_c: lex.yy.c mini_c.tab.c mini_c.tab.h
	g++ -g -O0 -std=c++11 -Werror=return-type -o mini_c mini_c.tab.c lex.yy.c

clean:
	rm mini_c mini_c.tab.c lex.yy.c mini_c.tab.h
