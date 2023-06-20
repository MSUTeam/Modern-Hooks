::Hooks.QueueBucket <- {
	First = 0,
	Early = 1,
	Normal = 2,
	Late = 3,
	VeryLate = 4,
	Last = 5
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
