::Hooks.QueueBucket <- {
	First = 0,
	VeryEarly = 1
	Early = 2,
	Normal = 3,
	Late = 4,
	VeryLate = 5,
	Last = 6,
	AfterHooks = 7
};

::Hooks.Operator <- {
	LT = 1, // <
	LE = 2, // <=
	EQ = 3, // ==
	NE = 4 // !=
	GE = 5 // >=
	GT = 6, // >
};

::Hooks.CompatibilityCheckResult <- {
	Success = 0,
	TooSmall = 1,
	TooBig = 2,
	Incorrect = 3,
	ModMissing = 4,
	ModPresent = 5
};

::Hooks.CompatibilityType <- {
	Requirement = 1,
	Incompatibility = 2
};
