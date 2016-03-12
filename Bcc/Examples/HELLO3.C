

struct var
{
	char	e1;
	long	e2;
} var;

main()
{
	struct var v, *vp;

	printf("Hello world -- hello3.c\n");
	v.e1 = 1;
	v.e2 = 2;
	vp = & var;
	vp -> e1 = -1;
	vp -> e2 = -2;
}


