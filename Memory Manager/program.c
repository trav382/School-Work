#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>	// For mmap() function
#include <string.h> 	// For memcpy() function
#include <fcntl.h> 	// For file descriptors

#define BUFFER_SIZE 16	// Size of logical addresses

#define OFFSET_MASK 255 // 2^8 - 1 
#define PAGES 256 	// address space / page size = 2^16/2^8
#define OFFSET_BITS 8 	// Page size is 2^8
#define PAGE_SIZE 256 	// As given
#define MAXTLB 16	// Size of TLB

char * mmapfptr;        // 
int oldestentry = 0;    // used for FIFO in TLB
int updated = 0;	// Flag to know if TLB_Update has been called
int page_table[PAGES];  // Page table with 256 entries for the 256 pages


/**
 * Structure to represent the TLB. 2 members, page number and frame number 
 */
struct TLBentry {
	int pagenumber;
	int framenumber;
};

struct TLBentry tlb[MAXTLB];	// Declare array of 16 TLB entries to from TLB


/** Function that searches the TLB for an entry 
 *  corresponding to the given page number (pn).
 *  Returns index if found, and a -1 if entry does not exist.
 *  Param pn is the page number that will be searched for, integer arguement.
 */
int search_TLB(int pn) {
	
	for (int i = 0; i < MAXTLB; i++)
	{
		if (tlb[i].pagenumber == pn)
		{
			return i;
		}
	}
	return -1;
}


/** Function that adds an entry to the TLB.
 *  Follows FIFO policy, if full, TLB replaces oldest entry.
 *  Param entry is a TLB struct, that will be added to tlb.
 */
void TLB_Add(struct TLBentry entry){
	
	tlb[oldestentry] = entry;
	
	if (oldestentry == 15)	// Reset index to 0 if index is at the end of the array.
	{
		oldestentry = 0;
	}
	else {oldestentry++;}
}


/** Function that updates the TLB when a page 'p' is replaced in physical memory. 
 *  Param p is the page that was replaced in physical memory.
 *  Param newp is the entry that will replace 'p' IF p is currently in the TLB.
 */
void TLB_Update(int p, int newp){
	
	int entry = search_TLB(p);
	if (entry >= 0)
	{
		tlb[entry].pagenumber = newp;
		updated = 1;
	}
}


/** Function that searches the page table for a frame number.
 *  Returns index if found, and a -1 if frame number is not in the array.
 *  Param fn is the frame number that will be searched for, integer arguement.
 */
int tablesearch(int fn){

	for (int i = 0; i < 256; i++)
	{
		if (page_table[i] == fn)
		{
			return i;
		}
	}
}


void main(){

	FILE *fptr = fopen("addresses.txt", "r");

	int logadd;		// Logical address
	int physadd;		// physical address
	int pagenum;		// Page number
	int pgoffset;		// Page offset
	int pagefaults = 0;	// # of page faults
	int tlbhits = 0;	// # of TLB hits
	char physical_mem[32768]; 

	int backstore_fd = open("BACKING_STORE.bin", O_RDONLY);
	mmapfptr = mmap(0, 65536, PROT_READ, MAP_PRIVATE, backstore_fd, 0);

	int i;
	/** 
 	*  Loop that initializes all page table entries to -1 to indicate page is not in memory.  
 	*/
	for(i=0; i < PAGES; i++) {
		page_table[i] = -1;   
	}

		

	int framenum;
	int oldestframe = 0;	// Index to keep track of the location of the oldest frame. Needed for FIFO.
	int miss;
	int full = 0;		// Flag to indicate if there are no available frames.
	char buff[BUFFER_SIZE];

	int addresscount = 0; // counter for the number of addresses for output

	/** 
 	*  Loop that will read from 'addresses.txt' until end of file.  
 	*/
	while(fgets(buff, BUFFER_SIZE, fptr) != NULL){

		miss = 0;		// Flag to indicate a TLB miss
		updated = 0;		// Flag to indicate TLB_update has updated the TLB.
		logadd = atoi(buff);    // Makes integer from char in buffer.
		pagenum = logadd >> OFFSET_BITS;
		pgoffset = logadd & OFFSET_MASK;

		int index = search_TLB(pagenum);	
		if (index >= 0)		// TLB hit
		{
			framenum = tlb[index].framenumber;	// Access frame number from TLB
			tlbhits++;
		}
		else // search returned -1 (page was not in TLB)
		{
			miss = 1;
		}

		/** If TLB miss happens, need to check page table for the frame number. */   
		if (miss)
		{
			framenum = page_table[pagenum];
		}
		
		if (framenum < 0) 	// Page fault
		{ 	
			pagefaults++;
			for (int i = 0; i < 256; i++)	// Copy page into physical memory byte by byte
			{
				memcpy(physical_mem + 256*oldestframe + i , mmapfptr + 256*pagenum + i, 1); 
			}
		
			if (full)
			{
				page_table[tablesearch(oldestframe)] = -1;	// Remove entry from page table for replacement	
			}

			int oldpage = page_table[oldestframe];	// oldest page in memory that will be replaced
			TLB_Update(oldpage, pagenum);		// swap new page with page that got replaced.

			page_table[pagenum] = oldestframe;	// put frame in page table
			framenum = oldestframe;

			if (oldestframe == 127)			// Set oldest frame to index 0 if array is full.
			{
				oldestframe = 0;
				full = 1;			// Indicate that physical memory is now full.
			} 
			else {oldestframe++;}                   // Incrememnt oldest frame.
		
		}

		/** If TLB misssed AND TLB has not been updated, add new tlb entry with frame # and page #  */
		if (miss && !updated)
		{
			struct TLBentry newentry;
			newentry.framenumber = framenum;
			newentry.pagenumber = pagenum;
			TLB_Add(newentry);
		}

		physadd = (framenum << OFFSET_BITS) | pgoffset; 	// Calculate physical address
		signed char value = physical_mem[physadd];		// Signed byte value at corresponding physical address
	
		printf("Virtual address: %d Physical address = %d Value=%d \n", logadd, physadd, value);
		addresscount++;
	}
	printf("Total addresses = %d \n", addresscount);
	printf("Page faults: %d \n", pagefaults);
	printf("TLB hits: %d \n", tlbhits);

	fclose(fptr); 
}
