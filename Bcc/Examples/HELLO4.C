

typedef struct var
{
	char	e1;
	long	e2;
} var_t;

var_t var;

main()
{
	var_t v, *vp;

	printf("Hello world -- hello4.c\n");
	v.e1 = 1;
	v.e2 = 2;
	vp = & var;
	vp -> e1 = -1;
	vp -> e2 = -2;
}


