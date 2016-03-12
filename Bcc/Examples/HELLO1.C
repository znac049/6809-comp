

main()
{
	int i;

	printf("Hello world\n");
	for(i = 0; i < 10; i++)
		printf("i = %d\n", i);
	fn1(i);
}


fn1(i)
int i;
{

	printf("Goodbye world\n");
	for(; i > 0; --i)
		printf("i = %d\n", fn2(i));
}

int fn2(i)
int i;
{
	switch(i)
	{
	case 0:
		return -1;
		break;
	
	case 1:
		return 0;
		break;

	default:
		return 1;
		break;
	}
}




