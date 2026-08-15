import { Body, Controller, Get, Post, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StorageService } from '../common/storage.service';

function parseYearOrSemester(val?: string): number[] | undefined {
  if (!val) return undefined;
  const num = Number(val);
  if (isNaN(num)) return undefined;
  if (num === 1) return [1, 2];
  if (num === 2) return [3, 4];
  if (num === 3) return [5, 6];
  if (num === 4) return [7, 8];
  return [num];
}

@ApiTags('academic')
@Controller()
export class AcademicController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  private async signUrl(s3Key?: string | null, fileUrl?: string | null): Promise<string | undefined> {
    if (s3Key) {
      return this.storage.publicUrlFor(s3Key);
    }
    if (fileUrl && fileUrl.includes('amazonaws.com/')) {
      const key = fileUrl.split('.amazonaws.com/')[1]?.split('?')[0];
      if (key) return this.storage.publicUrlFor(key);
    }
    return fileUrl || undefined;
  }

  // GET /subjects?branch=CSE&year=1 (or &semester=1)
  @Get('subjects')
  async listSubjects(
    @Query('branch') branch?: string,
    @Query('year') year?: string,
    @Query('semester') semester?: string
  ) {
    const semFilter = parseYearOrSemester(year || semester);
    const subjects = await this.prisma.subject.findMany({
      where: {
        ...(branch ? { branch } : {}),
        ...(semFilter ? { semester: { in: semFilter } } : {}),
      },
      include: { contents: true },
      orderBy: { name: 'asc' },
    });

    return Promise.all(
      subjects.map(async (subj) => ({
        ...subj,
        contents: await Promise.all(
          subj.contents.map(async (c) => ({
            ...c,
            fileUrl: await this.signUrl(c.s3Key, c.fileUrl),
          }))
        ),
      }))
    );
  }

  // GET /job-listings?type=INTERNSHIP
  @Get('job-listings')
  async listJobs(@Query('type') type?: 'INTERNSHIP' | 'PLACEMENT' | 'GOVT_JOB', @Query('branch') branch?: string) {
    const jobs = await this.prisma.jobListing.findMany({
      where: {
        ...(type ? { type } : {}),
        ...(branch ? { branch } : {}),
      },
      orderBy: { postedAt: 'desc' },
    });

    return Promise.all(
      jobs.map(async (job) => ({
        ...job,
        fileUrl: job.fileUrl ? await this.signUrl(job.s3Key, job.fileUrl) : undefined,
      }))
    );
  }

  // GET /results?year=1 (or &semester=1)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('results')
  async getResults(@Req() req: any, @Query('year') year?: string, @Query('semester') semester?: string) {
    const hallTicket = req.user.hallTicket;
    const semFilter = parseYearOrSemester(year || semester);
    const results = await this.prisma.result.findMany({
      where: {
        hallTicket,
        ...(semFilter ? { semester: { in: semFilter } } : {}),
      },
      orderBy: { semester: 'asc' },
    });

    return Promise.all(
      results.map(async (res) => ({
        ...res,
        fileUrl: await this.signUrl(res.s3Key, res.fileUrl),
      }))
    );
  }

  // GET /aptitude?category=quantitative
  @Get('aptitude')
  async listAptitude(@Query('category') category?: string) {
    return this.prisma.aptitudeQuestion.findMany({
      where: category ? { category } : {},
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  // GET /announcements & GET /api/circulars
  @Get('announcements')
  @Get('api/circulars')
  async listAnnouncements() {
    const items = await this.prisma.announcement.findMany({
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
    return { circulars: items, announcements: items };
  }

  // POST /api/interview/question
  @Post('api/interview/question')
  async getInterviewQuestion(@Body() body: any) {
    const { mode = 'technical', topic = 'general software engineering', difficulty = 'medium' } = body || {};

    const techQuestions = [
      { question: "Explain the difference between Process and Thread in Operating Systems, and how context switching works.", type: "Technical CS", hint: "Think about shared memory space vs isolated process address space." },
      { question: "How does a Hash Table achieve O(1) average time complexity for search and insertion? What happens during collision?", type: "Technical DS", hint: "Discuss chaining vs open addressing methods." },
      { question: "What is the difference between SQL and NoSQL databases? When would you choose MongoDB over PostgreSQL?", type: "Technical DBMS", hint: "Consider ACID compliance vs horizontal scaling flexibility." },
      { question: "Explain the concept of Polymorphism in Object-Oriented Programming with a real-world example.", type: "Technical OOP", hint: "Differentiate compile-time (overloading) vs runtime (overriding) polymorphism." }
    ];

    const hrQuestions = [
      { question: "Tell me about a challenging project you worked on. How did you resolve technical conflicts within your team?", type: "HR Behavioral", hint: "Use the STAR method: Situation, Task, Action, Result." },
      { question: "Where do you see yourself in 3 years, and why are you interested in joining our company's engineering team?", type: "HR Career", hint: "Align your career growth with technical contributions." },
      { question: "How do you handle strict project deadlines when unexpected bugs arise near release time?", type: "HR Work Ethic", hint: "Focus on prioritization, communication, and systematic debugging." }
    ];

    const aptitudeQuestions = [
      { question: "A train running at 72 km/h crosses a 200m long platform in 25 seconds. What is the length of the train in meters?", type: "Quantitative Aptitude", hint: "Speed in m/s = 72 * (5/18) = 20 m/s. Total distance = Speed * Time." },
      { question: "If 6 men and 8 boys can complete a work in 10 days, while 26 men and 48 boys can do it in 2 days, find the time taken by 15 men and 20 boys to complete it.", type: "Work & Time", hint: "Equate total work units: 10(6M + 8B) = 2(26M + 48B)." }
    ];

    const pool = mode === 'aptitude' ? aptitudeQuestions : mode === 'hr' ? hrQuestions : techQuestions;
    const selected = pool[Math.floor(Math.random() * pool.length)];
    return selected;
  }

  // POST /api/interview/feedback
  @Post('api/interview/feedback')
  async evaluateInterviewFeedback(@Body() body: any) {
    const { question, answer, mode = 'technical' } = body || {};
    if (!question || !answer) {
      return { error: 'question and answer are required' };
    }

    const wordCount = (answer || '').trim().split(/\s+/).length;
    let score = Math.min(10, Math.max(5, Math.floor(wordCount / 8) + 5));
    if (wordCount < 10) score = 4;

    return {
      score,
      strengths: [
        "Good initiative and structured response.",
        "Clear understanding of core concepts mentioned in the question.",
        "Direct communication style suitable for campus placement interviews."
      ],
      improvements: [
        "Include 1-2 real-world technical examples or project scenarios.",
        "Elaborate on edge cases or performance tradeoffs.",
        "Structure answer using the STAR format (Situation, Task, Action, Result)."
      ],
      modelAnswerSummary: "A strong model answer covers key terminology, step-by-step logic, practical use-cases, and efficiency considerations."
    };
  }
}
